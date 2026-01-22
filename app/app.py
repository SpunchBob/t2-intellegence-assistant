from flask import Flask, request, jsonify
from flask_restx import Api, Resource, fields
from typing import Dict, List, Any
import numpy as np
from datetime import datetime
import json
import os

app = Flask(__name__)
api = Api(app, version='1.0', title='Recommendation System API',
          description='Система рекомендаций на основе действий пользователей')

# Модели данных
ns = api.namespace('recommendations', description='Операции рекомендаций')

user_action_model = api.model('UserAction', {
    'user_id': fields.Integer(required=True, description='ID пользователя'),
    'action_type': fields.String(required=True, description='Тип действия'),
    'action_count': fields.Integer(required=True, description='Количество действий'),
    'timestamp': fields.String(description='Временная метка')
})

category_model = api.model('Category', {
    'category_id': fields.Integer(description='ID категории'),
    'category_name': fields.String(description='Название категории'),
    'priority': fields.Float(description='Приоритет категории')
})

# Карта соответствия действий категориям
ACTION_TO_CATEGORY_MAP = {
    'view_purchases': 'electronics',
    'use_function_x': 'software',
    'view_fashion': 'clothing',
    'search_books': 'books',
    'watch_videos': 'entertainment',
    'browse_gadgets': 'electronics',
    'read_articles': 'education'
}

CATEGORY_WEIGHTS = {
    'electronics': 1.2,
    'software': 1.0,
    'clothing': 0.8,
    'books': 0.9,
    'entertainment': 1.1,
    'education': 0.7
}

class RecommendationSystem:
    def __init__(self):
        self.user_profiles = {}
        self.category_scores = {}
        
    def process_actions(self, user_id: int, actions: List[Dict]) -> Dict[str, float]:
        """Обработка действий пользователя и расчет приоритетов категорий"""
        if user_id not in self.user_profiles:
            self.user_profiles[user_id] = {}
            self.category_scores[user_id] = {}
        
        for action in actions:
            action_type = action['action_type']
            count = action['action_count']
            
            # Определяем категорию по типу действия
            category = self._map_action_to_category(action_type)
            
            if category:
                # Обновляем счетчик категории
                current_score = self.category_scores[user_id].get(category, 0)
                weight = CATEGORY_WEIGHTS.get(category, 1.0)
                
                # Учитываем вес категории и количество действий
                self.category_scores[user_id][category] = current_score + (count * weight)
        
        return self._calculate_priorities(user_id)
    
    def _map_action_to_category(self, action_type: str) -> str:
        """Сопоставление типа действия с категорией"""
        for key, category in ACTION_TO_CATEGORY_MAP.items():
            if key in action_type.lower():
                return category
        return None
    
    def _calculate_priorities(self, user_id: int) -> Dict[str, float]:
        """Расчет приоритетов категорий для пользователя"""
        if user_id not in self.category_scores:
            return {}
        
        scores = self.category_scores[user_id]
        if not scores:
            return {}
        
        # Нормализация оценок
        total = sum(scores.values())
        priorities = {}
        
        for category, score in scores.items():
            # Применяем softmax для получения вероятностей
            priorities[category] = score / total if total > 0 else 0
        
        # Сортировка по приоритету
        sorted_priorities = dict(sorted(
            priorities.items(), 
            key=lambda x: x[1], 
            reverse=True
        ))
        
        return sorted_priorities
    
    def get_recommendations(self, user_id: int, top_n: int = 3) -> List[Dict]:
        """Получение рекомендаций для пользователя"""
        priorities = self._calculate_priorities(user_id)
        
        recommendations = []
        for i, (category, priority) in enumerate(list(priorities.items())[:top_n]):
            recommendations.append({
                'category_id': i + 1,
                'category_name': category,
                'priority': round(priority, 4),
                'rank': i + 1
            })
        
        return recommendations

# Инициализация системы рекомендаций
recommendation_system = RecommendationSystem()

@ns.route('/process')
class ProcessActions(Resource):
    @ns.expect([user_action_model])
    @ns.response(200, 'Success')
    def post(self):
        """Обработка действий пользователя и получение рекомендаций"""
        data = request.json
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Группируем действия по пользователям
        user_actions = {}
        for action in data:
            user_id = action['user_id']
            if user_id not in user_actions:
                user_actions[user_id] = []
            user_actions[user_id].append(action)
        
        results = {}
        for user_id, actions in user_actions.items():
            priorities = recommendation_system.process_actions(user_id, actions)
            recommendations = recommendation_system.get_recommendations(user_id)
            
            results[user_id] = {
                'processed_actions': len(actions),
                'priorities': priorities,
                'recommendations': recommendations,
                'timestamp': datetime.now().isoformat()
            }
        
        return jsonify(results)

@ns.route('/recommend/<int:user_id>')
class GetRecommendations(Resource):
    @ns.response(200, 'Success')
    def get(self, user_id):
        """Получение рекомендаций для конкретного пользователя"""
        recommendations = recommendation_system.get_recommendations(user_id)
        
        if not recommendations:
            return jsonify({
                'user_id': user_id,
                'message': 'No recommendations available. Process some actions first.',
                'recommendations': []
            })
        
        return jsonify({
            'user_id': user_id,
            'timestamp': datetime.now().isoformat(),
            'recommendations': recommendations
        })

@ns.route('/health')
class HealthCheck(Resource):
    def get(self):
        """Проверка здоровья сервиса"""
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'users_processed': len(recommendation_system.user_profiles)
        })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)