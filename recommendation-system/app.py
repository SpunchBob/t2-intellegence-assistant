from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import datetime
from typing import Dict, List, Any, Optional
import json

# Создание FastAPI application
app = FastAPI(
    title="Recommendation System API",
    description="Система рекомендаций на основе действий пользователей",
    version="1.0.0",
    docs_url="/docs",  # Swagger UI будет на /docs
    redoc_url="/redoc"
)

# Модели Pydantic для валидации
class UserAction(BaseModel):
    user_id: int
    action: str
    action_count: int = 1
    timestamp: Optional[str] = None

class Recommendation(BaseModel):
    category: str
    priority: float
    rank: int
    suggestions: List[str]

class RecommendationResponse(BaseModel):
    user_id: int
    recommendations: List[Recommendation]
    count: int
    timestamp: str

# TODO: Заполните маппинг действий на категории
FRONTEND_TO_CATEGORY = {
    # Пример:
    # 'purchase_view': 'shopping',
    # 'book_search': 'reading',
    # Добавьте свои действия здесь
}

# TODO: Заполните веса категорий
CATEGORY_WEIGHTS = {
    # Пример:
    # 'shopping': 1.3,
    # 'reading': 1.0,
    # Добавьте свои категории и веса здесь
}

# TODO: Заполните предложения для категорий
CATEGORY_SUGGESTIONS = {
    # Пример:
    # 'shopping': ["Предложение 1", "Предложение 2"],
    # 'reading': ["Книги", "Статьи"],
    # Добавьте предложения для ваших категорий здесь
}

class SimpleRecommendationSystem:
    def __init__(self):
        self.user_profiles = {}
        
    def process_actions(self, actions: List[UserAction]) -> Dict[str, Any]:
        """Обработка действий от analytics collector"""
        results = {}
        
        for action in actions:
            try:
                user_id = action.user_id
                frontend_action = action.action
                count = action.action_count
                
                # Сопоставление действия с категорией
                category = self._map_action_to_category(frontend_action)
                if not category:
                    continue  # Пропускаем неизвестные действия
                
                # Инициализация профиля пользователя если нужно
                if user_id not in self.user_profiles:
                    self.user_profiles[user_id] = {}
                
                # Обновление счета категории
                weight = CATEGORY_WEIGHTS.get(category, 1.0)
                current_score = self.user_profiles[user_id].get(category, 0)
                self.user_profiles[user_id][category] = current_score + (count * weight)
                
                # Записываем результат
                if user_id not in results:
                    results[user_id] = {'processed': 0, 'categories': set()}
                
                results[user_id]['processed'] += 1
                results[user_id]['categories'].add(category)
                
            except Exception as e:
                print(f"Ошибка обработки действия: {e}")
                continue
        
        # Форматируем ответ
        formatted_results = {}
        for user_id, stats in results.items():
            formatted_results[user_id] = {
                'actions_processed': stats['processed'],
                'categories_affected': list(stats['categories']),
                'timestamp': datetime.now().isoformat()
            }
        
        return formatted_results
    
    def _map_action_to_category(self, frontend_action: str) -> str:
        """Сопоставление действия от фронтенда с категорией"""
        return FRONTEND_TO_CATEGORY.get(frontend_action)
    
    def get_recommendations(self, user_id: int, top_n: int = 5) -> List[Dict[str, Any]]:
        """Получение рекомендаций для пользователя"""
        # Проверяем есть ли профиль пользователя
        if user_id not in self.user_profiles or not self.user_profiles[user_id]:
            return self._get_fallback_recommendations()
        
        scores = self.user_profiles[user_id]
        
        # Рассчитываем приоритеты
        total_score = sum(scores.values())
        if total_score == 0:
            return self._get_fallback_recommendations()
        
        # Создаем рекомендации
        recommendations = []
        sorted_categories = sorted(
            scores.items(), 
            key=lambda x: x[1], 
            reverse=True
        )
        
        for i, (category, score) in enumerate(sorted_categories[:top_n]):
            priority = score / total_score
            
            # Получаем предложения для категории
            suggestions = CATEGORY_SUGGESTIONS.get(category, ["Исследовать категорию"])
            
            recommendations.append({
                'category': category,
                'priority': round(priority, 4),
                'rank': i + 1,
                'suggestions': suggestions[:3]  # Первые 3 предложения
            })
        
        return recommendations
    
    def _get_fallback_recommendations(self) -> List[Dict[str, Any]]:
        """Рекомендации по умолчанию (если нет данных)"""
        return [
            {
                'category': 'general',
                'priority': 1.0,
                'rank': 1,
                'suggestions': ['Исследовать приложение', 'Попробовать разные функции']
            }
        ]
    
    def get_user_profile(self, user_id: int) -> Dict[str, Any]:
        """Получение профиля пользователя для отладки"""
        if user_id in self.user_profiles:
            return {
                'user_id': user_id,
                'profile': self.user_profiles[user_id],
                'last_updated': datetime.now().isoformat()
            }
        return {'error': 'User not found'}

# Инициализация системы рекомендаций
recommendation_system = SimpleRecommendationSystem()

# API Endpoints
@app.post("/process")
async def process_actions(actions: List[UserAction]):
    """Прием и обработка действий от analytics collector"""
    try:
        # Обрабатываем действия
        results = recommendation_system.process_actions(actions)
        
        return {
            'status': 'success',
            'results': results,
            'total_users': len(results),
            'timestamp': datetime.now().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/recommend/{user_id}")
async def get_recommendations(user_id: int, top_n: int = 5):
    """Получение рекомендаций для пользователя"""
    recommendations = recommendation_system.get_recommendations(user_id, top_n)
    
    return RecommendationResponse(
        user_id=user_id,
        recommendations=recommendations,
        count=len(recommendations),
        timestamp=datetime.now().isoformat()
    )

@app.get("/profile/{user_id}")
async def get_user_profile(user_id: int):
    """Получение профиля пользователя (для отладки)"""
    profile = recommendation_system.get_user_profile(user_id)
    return profile

@app.get("/health")
async def health_check():
    """Проверка здоровья сервиса"""
    return {
        'status': 'healthy',
        'service': 'recommendation-system',
        'version': '1.0',
        'users_count': len(recommendation_system.user_profiles),
        'timestamp': datetime.now().isoformat()
    }

@app.get("/config")
async def config_info():
    """Информация о текущей конфигурации"""
    return {
        'frontend_to_category_mapping': FRONTEND_TO_CATEGORY,
        'category_weights': CATEGORY_WEIGHTS,
        'category_suggestions': list(CATEGORY_SUGGESTIONS.keys()),
        'note': 'TODO: Заполните эти словари своими данными'
    }

@app.post("/debug/reset")
async def reset_system():
    """Сброс всех данных (только для тестирования!)"""
    recommendation_system.__init__()
    return {
        'status': 'reset',
        'message': 'System reset successfully',
        'timestamp': datetime.now().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    
    print(f"=== Recommendation System API ===")
    print(f"Запуск: {datetime.now().isoformat()}")
    print(f"Swagger UI: http://localhost:5000/docs")
    print(f"Health check: http://localhost:5000/health")
    print(f"=================================")
    
    uvicorn.run(app, host="0.0.0.0", port=5000)