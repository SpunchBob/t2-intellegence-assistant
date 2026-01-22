from flask import Flask, request, jsonify
from flask_restx import Api, Resource, fields
import numpy as np
from datetime import datetime, timedelta
import logging
from typing import Dict, List
import redis
import json

# Создание Flask-application и API 

app = Flask(__name__)
api = Api(app, version='2.0', title='Enhanced Recommendation Engine',
          description='Улучшенная система рекомендаций с поддержкой аналитики')

# Настройка Redis и создание клиента Redis

REDIS_HOST = "redis"
REDIS_PORT = 6379
redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

# Модели для Swagger

action_model = api.model('AnalyticsAction', {
    'user_id': fields.Integer(required=True),
    'action_type': fields.String(required=True),
    'action_count': fields.Integer(required=True),
    'timestamp': fields.String()
})

recommendation_model = api.model('EnhancedRecommendation', {
    'category': fields.String(description='Категория'),
    'priority': fields.Float(description='Приоритет 0-1'),
    'confidence': fields.Float(description='Уверенность в рекомендации'),
    'reason': fields.String(description='Обоснование рекомендации'),
    'suggested_actions': fields.List(fields.String, description='Предлагаемые действия')
})

# Маппинг действий на категории с весами
ACTION_CATEGORY_MAPPING = {
    'chatting_assitant': {
        'category': 'chat',
        'weight': 1.2,
        'decay_rate': 0.95  # Коэффициент затухания со временем
    },
    'search_books': {
        'category': 'time',
        'weight': 0.9,
        'decay_rate': 0.9
    },
    'watch_videos': {
        'category': 'messages',
        'weight': 1.1,
        'decay_rate': 0.85
    },
    'read_articles': {
        'category': 'education',
        'weight': 0.7,
        'decay_rate': 0.8
    },
    'use_function_x': {
        'category': 'software',
        'weight': 1.0,
        'decay_rate': 0.9
    }
}

class EnhancedRecommendationSystem:
    def __init__(self):
        self.user_profiles = {}
        self.category_decay = {}  # Для учета времени
        
    def process_batch_actions(self, actions: List[Dict]):
        """Пакетная обработка действий из analytics collector"""
        results = {}
        
        for action in actions:
            user_id = action['user_id']
            action_type = action['action_type']
            count = action['action_count']
            
            if user_id not in self.user_profiles:
                self.user_profiles[user_id] = {}
                self.category_decay[user_id] = {}
            
            # Получаем настройки категории
            category_config = ACTION_CATEGORY_MAPPING.get(action_type)
            if not category_config:
                continue
            
            category = category_config['category']
            weight = category_config['weight']
            decay_rate = category_config['decay_rate']
            
            # Применяем затухание старых действий
            self._apply_decay(user_id, category, decay_rate)
            
            # Добавляем новые действия
            current_score = self.user_profiles[user_id].get(category, 0)
            self.user_profiles[user_id][category] = current_score + (count * weight)
            
            # Обновляем время последнего действия
            self.category_decay[user_id][category] = datetime.now()
            
            # Сохраняем в Redis для persistence
            self._save_to_redis(user_id)
            
            if user_id not in results:
                results[user_id] = {'processed': 0, 'categories': set()}
            
            results[user_id]['processed'] += 1
            results[user_id]['categories'].add(category)
        
        return results
    
    def _apply_decay(self, user_id: int, category: str, decay_rate: float):
        """Применение затухания к старым действиям"""
        if user_id in self.user_profiles and category in self.user_profiles[user_id]:
            last_update = self.category_decay[user_id].get(category)
            if last_update:
                hours_passed = (datetime.now() - last_update).total_seconds() / 3600
                decay_factor = decay_rate ** (hours_passed / 24)  # Дневное затухание
                self.user_profiles[user_id][category] *= decay_factor
    
    def _save_to_redis(self, user_id: int):
        """Сохранение профиля пользователя в Redis"""
        if redis_client:
            key = f"user_profile:{user_id}"
            profile_data = {
                'scores': self.user_profiles.get(user_id, {}),
                'last_updated': datetime.now().isoformat()
            }
            redis_client.setex(key, 604800, json.dumps(profile_data))  # TTL 7 дней
    
    def _load_from_redis(self, user_id: int):
        """Загрузка профиля пользователя из Redis"""
        if redis_client:
            key = f"user_profile:{user_id}"
            data = redis_client.get(key)
            if data:
                profile_data = json.loads(data)
                self.user_profiles[user_id] = profile_data['scores']
                return True
        return False
    
    def get_enhanced_recommendations(self, user_id: int, context: Dict = None) -> List[Dict]:
        """Получение улучшенных рекомендаций с контекстом"""
        
        # Пытаемся загрузить из Redis
        if user_id not in self.user_profiles:
            self._load_from_redis(user_id)
        
        if user_id not in self.user_profiles or not self.user_profiles[user_id]:
            return self._get_fallback_recommendations()
        
        scores = self.user_profiles[user_id]
        
        # Рассчитываем приоритеты
        total_score = sum(scores.values())
        if total_score == 0:
            return self._get_fallback_recommendations()
        
        # Нормализация и добавление метаданных
        recommendations = []
        for category, score in scores.items():
            priority = score / total_score
            
            # Рассчитываем уверенность на основе количества данных
            confidence = min(0.95, 0.3 + (len(scores) * 0.1))
            
            # Генерируем обоснование
            reason = self._generate_reason(category, score, priority)
            
            # Предлагаемые действия
            suggested_actions = self._get_suggested_actions(category)
            
            recommendations.append({
                'category': category,
                'priority': round(priority, 4),
                'confidence': round(confidence, 2),
                'reason': reason,
                'suggested_actions': suggested_actions
            })
        
        # Сортируем по приоритету и уверенности
        recommendations.sort(key=lambda x: (x['priority'], x['confidence']), reverse=True)
        
        # Применяем контекстные фильтры если есть
        if context:
            recommendations = self._apply_context_filters(recommendations, context)
        
        return recommendations[:5]  # Топ-5 рекомендаций
    
    def _generate_reason(self, category: str, score: float, priority: float) -> str:
        """Генерация обоснования рекомендации"""
        reasons = {
            'electronics': f"Вы проявили интерес к электронике ({priority:.0%} активности)",
            'books': f"На основе вашего интереса к чтению ({priority:.0%} активности)",
            'entertainment': f"Вы часто смотрите развлекательный контент",
            'education': f"Ваша активность в обучении высока",
            'software': f"Вы активно используете функционал системы"
        }
        return reasons.get(category, f"На основе вашей активности в категории {category}")
    
    def _get_suggested_actions(self, category: str) -> List[str]:
        """Получение предлагаемых действий для категории"""
        suggestions = {
            'electronics': ["Посмотреть новые гаджеты", "Сравнить цены", "Почитать обзоры"],
            'books': ["Поискать новинки", "Посмотреть бестселлеры", "Выбрать по жанру"],
            'entertainment': ["Посмотреть рекомендации", "Подборка по интересам", "Популярное сейчас"],
            'education': ["Новые курсы", "Статьи по теме", "Вебинары"],
            'software': ["Изучить новые функции", "Настройки профиля", "Советы по использованию"]
        }
        return suggestions.get(category, ["Исследовать категорию"])
    
    def _get_fallback_recommendations(self) -> List[Dict]:
        """Рекомендации по умолчанию"""
        return [
            {
                'category': 'electronics',
                'priority': 0.3,
                'confidence': 0.5,
                'reason': 'Популярная категория среди пользователей',
                'suggested_actions': ['Посмотреть новинки', 'Специальные предложения']
            },
            {
                'category': 'books',
                'priority': 0.25,
                'confidence': 0.5,
                'reason': 'Часто просматриваемая категория',
                'suggested_actions': ['Бестселлеры', 'Новинки']
            }
        ]
    
    def _apply_context_filters(self, recommendations: List[Dict], context: Dict) -> List[Dict]:
        """Применение контекстных фильтров"""
        filtered = []
        
        for rec in recommendations:
            # Пример фильтрации по времени суток
            if 'time_of_day' in context:
                if context['time_of_day'] == 'morning' and rec['category'] == 'education':
                    rec['priority'] *= 1.2
                elif context['time_of_day'] == 'evening' and rec['category'] == 'entertainment':
                    rec['priority'] *= 1.3
            
            filtered.append(rec)
        
        filtered.sort(key=lambda x: x['priority'], reverse=True)
        return filtered

# Инициализация системы
rec_system = EnhancedRecommendationSystem()

@api.route('/process/batch')
class ProcessBatch(Resource):
    @api.expect([action_model])
    @api.doc(description='Пакетная обработка действий от analytics collector')
    def post(self):
        """Обработка батча действий"""
        actions = request.json
        
        if not isinstance(actions, list):
            return {'error': 'Expected a list of actions'}, 400
        
        results = rec_system.process_batch_actions(actions)
        
        # Форматируем ответ
        response = {}
        for user_id, stats in results.items():
            response[user_id] = {
                'actions_processed': stats['processed'],
                'categories_affected': list(stats['categories']),
                'timestamp': datetime.now().isoformat()
            }
        
        return response

@api.route('/recommend/enhanced/<int:user_id>')
class EnhancedRecommendations(Resource):
    @api.doc(description='Получение улучшенных рекомендаций с контекстом')
    @api.param('context', 'Контекстные данные (JSON)')
    def get(self, user_id):
        """Получение рекомендаций с контекстом"""
        context_str = request.args.get('context')
        context = json.loads(context_str) if context_str else {}
        
        recommendations = rec_system.get_enhanced_recommendations(user_id, context)
        
        return {
            'user_id': user_id,
            'timestamp': datetime.now().isoformat(),
            'context_used': bool(context),
            'recommendations': recommendations
        }

@api.route('/profile/<int:user_id>')
class UserProfile(Resource):
    def get(self, user_id):
        """Получение профиля пользователя"""
        if user_id in rec_system.user_profiles:
            return {
                'user_id': user_id,
                'profile': rec_system.user_profiles[user_id],
                'last_updated': datetime.now().isoformat()
            }
        return {'message': 'Profile not found'}, 404

@api.route('/health/redis')
class RedisHealth(Resource):
    def get(self):
        """Проверка подключения к Redis"""
        try:
            redis_client.ping()
            return {'redis': 'connected'}
        except:
            return {'redis': 'disconnected'}, 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)