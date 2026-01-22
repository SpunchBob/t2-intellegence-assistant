📊 Recommendation System API - Руководство для Backend разработчика
🎯 Обзор системы

Recommendation System API - это микросервис для анализа действий пользователей и предоставления персонализированных рекомендаций. Система получает данные от Analytics Collector, обрабатывает их и формирует рекомендации для каждого пользователя.
📋 Содержание

    🚀 Быстрый старт

    🏗️ Архитектура

    📡 API Endpoints

    🔧 Конфигурация

    🎯 Примеры использования

    🐳 Docker развертывание

    🔍 Отладка и мониторинг

🚀 Быстрый старт
1. Установка зависимостей
bash

pip install fastapi uvicorn

2. Запуск сервиса
bash

# В режиме разработки
python recommendation_system.py

# Или через uvicorn напрямую
uvicorn recommendation_system:app --host 0.0.0.0 --port 5000 --reload

3. Проверка работоспособности
bash

curl http://localhost:5000/health

Ожидаемый ответ:
json

{
  "status": "healthy",
  "service": "recommendation-system",
  "version": "1.0",
  "users_count": 0,
  "timestamp": "2024-01-22T10:30:00.000Z"
}

🏗️ Архитектура
Схема взаимодействия
text

┌─────────────┐    WebSocket    ┌─────────────────┐    REST API    ┌─────────────────────┐
│   Frontend  │ ───────────────▶│   Analytics     │ ──────────────▶│   Recommendation    │
│             │   (действия)    │   Collector     │   POST /process│   System API        │
└─────────────┘                 └─────────────────┘                └─────────────────────┘
                                      │                                    │
                                      ▼                                    ▼
                               ┌──────────────┐                    ┌─────────────────┐
                               │   Redis      │                    │   Ваш Backend   │
                               │   (опционально)│                    │   (GET /recommend)│
                               └──────────────┘                    └─────────────────┘

Поток данных:

    Frontend → Analytics Collector: WebSocket с действиями пользователя

    Analytics Collector → Recommendation System: POST /process с агрегированными данными

    Ваш Backend → Recommendation System: GET /recommend/{user_id} для получения рекомендаций

    Recommendation System → Ваш Backend: JSON с рекомендациями

📡 API Endpoints
1. POST /process - Обработка действий

Принимает батч действий от Analytics Collector.

Content-Type: application/json

Пример запроса:
json

[
  {
    "user_id": 12345,
    "action": "chatting_assistant",
    "action_count": 5,
    "timestamp": "2024-01-22T10:30:00.000Z"
  },
  {
    "user_id": 12345,
    "action": "book_search",
    "action_count": 3,
    "timestamp": "2024-01-22T11:00:00.000Z"
  },
  {
    "user_id": 67890,
    "action": "video_watch",
    "action_count": 10,
    "timestamp": "2024-01-22T12:00:00.000Z"
  }
]

Пример ответа:
json

{
  "status": "success",
  "results": {
    "12345": {
      "actions_processed": 2,
      "categories_affected": ["chat", "reading"],
      "timestamp": "2024-01-22T10:35:00.000Z"
    },
    "67890": {
      "actions_processed": 1,
      "categories_affected": ["entertainment"],
      "timestamp": "2024-01-22T10:35:00.000Z"
    }
  },
  "total_users": 2,
  "timestamp": "2024-01-22T10:35:00.000Z"
}

2. GET /recommend/{user_id} - Получение рекомендаций

Возвращает персонализированные рекомендации для пользователя.

Параметры:

    user_id (path): ID пользователя

    top_n (query, optional): Количество рекомендаций (по умолчанию: 5)

Пример запроса:
bash

GET /recommend/12345?top_n=3

Пример ответа:
json

{
  "user_id": 12345,
  "recommendations": [
    {
      "category": "chat",
      "priority": 0.625,
      "rank": 1,
      "suggestions": [
        "Начать новый диалог",
        "Популярные темы обсуждения",
        "Рекомендуемые собеседники"
      ]
    },
    {
      "category": "reading",
      "priority": 0.375,
      "rank": 2,
      "suggestions": [
        "Новые книги в категории",
        "Популярные авторы",
        "Рекомендуемые жанры"
      ]
    }
  ],
  "count": 2,
  "timestamp": "2024-01-22T10:40:00.000Z"
}

3. GET /profile/{user_id} - Профиль пользователя (отладка)

Показывает внутренний профиль пользователя.
4. GET /health - Проверка здоровья

Проверка работоспособности сервиса.
5. GET /config - Конфигурация

Показывает текущие настройки системы.
6. POST /debug/reset - Сброс данных

Сброс всех данных (только для тестирования!).
🔧 Конфигурация
Настройка маппинга действий

Отредактируйте словари в коде:
python

# 1. FRONTEND_TO_CATEGORY - маппинг действий от фронтенда на категории
FRONTEND_TO_CATEGORY = {
    'chatting_assistant': 'chat',
    'book_search': 'reading',
    'video_watch': 'entertainment',
    'article_read': 'education',
    'profile_view': 'profile',
    'settings_open': 'settings',
    'search_action': 'searching'
}

# 2. CATEGORY_WEIGHTS - веса категорий (влияют на приоритет)
CATEGORY_WEIGHTS = {
    'chat': 1.4,           # Высокий приоритет
    'reading': 1.0,        # Средний приоритет
    'entertainment': 1.2,  # Выше среднего
    'education': 0.9,      # Ниже среднего
    'profile': 0.7,        # Низкий приоритет
    'settings': 0.5,       # Очень низкий приоритет
    'searching': 1.0       # Средний приоритет
}

# 3. CATEGORY_SUGGESTIONS - предложения для каждой категории
CATEGORY_SUGGESTIONS = {
    'chat': [
        "Начать новый диалог",
        "Популярные темы обсуждения",
        "Рекомендуемые собеседники"
    ],
    'reading': [
        "Новые книги в категории",
        "Популярные авторы",
        "Рекомендуемые жанры"
    ],
    'entertainment': [
        "Популярные видео",
        "Рекомендации по фильмам",
        "Музыкальные подборки"
    ],
    'education': [
        "Новые статьи",
        "Обучающие материалы",
        "Популярные курсы"
    ]
}

Формула расчета приоритета
text

приоритет_категории = Σ(действия × вес_категории) / Σ(все_действия)

Пример:

    Действия пользователя 123:

        chatting_assistant: 5 раз (вес 1.4) = 5 × 1.4 = 7.0

        book_search: 3 раза (вес 1.0) = 3 × 1.0 = 3.0

    Итого: 7.0 + 3.0 = 10.0

    Приоритеты:

        chat: 7.0 / 10.0 = 0.7 (70%)

        reading: 3.0 / 10.0 = 0.3 (30%)

🎯 Примеры использования
Интеграция в ваш Backend
python

import requests
import json
from typing import List, Dict, Any

class RecommendationClient:
    def __init__(self, base_url: str = "http://localhost:5000"):
        self.base_url = base_url
    
    def get_user_recommendations(self, user_id: int, top_n: int = 5) -> Dict[str, Any]:
        """
        Получение рекомендаций для пользователя
        Используется вашим backend для отображения на фронтенде
        """
        try:
            response = requests.get(
                f"{self.base_url}/recommend/{user_id}",
                params={"top_n": top_n},
                timeout=3
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                # Fallback: возвращаем пустые рекомендации
                return {
                    "user_id": user_id,
                    "recommendations": [],
                    "count": 0,
                    "timestamp": "2024-01-22T00:00:00.000Z"
                }
                
        except requests.exceptions.RequestException:
            # Логируем ошибку и возвращаем fallback
            print(f"Recommendation service unavailable for user {user_id}")
            return {
                "user_id": user_id,
                "recommendations": [],
                "count": 0,
                    "timestamp": "2024-01-22T00:00:00.000Z"
            }
    
    def check_service_health(self) -> bool:
        """Проверка доступности сервиса рекомендаций"""
        try:
            response = requests.get(f"{self.base_url}/health", timeout=2)
            return response.status_code == 200
        except:
            return False
    
    def get_user_profile(self, user_id: int) -> Dict[str, Any]:
        """Получение профиля пользователя (для отладки/админки)"""
        try:
            response = requests.get(f"{self.base_url}/profile/{user_id}")
            return response.json() if response.status_code == 200 else {}
        except:
            return {}

# Использование
recommendation_client = RecommendationClient()

# В вашем контроллере пользователя
def get_user_dashboard(user_id: int):
    """
    Пример: получение данных для дашборда пользователя
    """
    # Получаем рекомендации
    recommendations = recommendation_client.get_user_recommendations(user_id, top_n=3)
    
    # Ваша бизнес-логика...
    user_data = {
        "user_id": user_id,
        "dashboard_data": {
            "recommendations": recommendations["recommendations"],
            "personalized_sections": self._prepare_sections(recommendations),
            "timestamp": recommendations["timestamp"]
        }
    }
    
    return user_data

def _prepare_sections(self, recommendations: Dict[str, Any]) -> List[Dict]:
    """
    Подготовка секций на основе рекомендаций
    """
    sections = []
    
    for rec in recommendations["recommendations"]:
        sections.append({
            "title": f"Рекомендуем: {rec['category']}",
            "priority": rec["priority"],
            "items": rec["suggestions"],
            "rank": rec["rank"]
        })
    
    return sections

Пример с кэшированием
python

import requests
from functools import lru_cache
from datetime import datetime, timedelta

class CachedRecommendationClient:
    def __init__(self, base_url: str = "http://localhost:5000", cache_ttl: int = 300):
        self.base_url = base_url
        self.cache_ttl = cache_ttl  # 5 минут
        self._cache = {}
    
    def get_user_recommendations(self, user_id: int, top_n: int = 5, force_refresh: bool = False) -> Dict[str, Any]:
        """
        Получение рекомендаций с кэшированием
        """
        cache_key = f"{user_id}_{top_n}"
        
        # Проверка кэша
        if not force_refresh and cache_key in self._cache:
            cached_data, cached_time = self._cache[cache_key]
            if datetime.now() - cached_time < timedelta(seconds=self.cache_ttl):
                return cached_data
        
        # Получение свежих данных
        try:
            response = requests.get(
                f"{self.base_url}/recommend/{user_id}",
                params={"top_n": top_n},
                timeout=3
            )
            
            if response.status_code == 200:
                data = response.json()
                # Сохраняем в кэш
                self._cache[cache_key] = (data, datetime.now())
                return data
            else:
                return self._get_fallback_recommendations(user_id)
                
        except requests.exceptions.RequestException:
            # Пытаемся вернуть кэшированные данные, даже если устарели
            if cache_key in self._cache:
                return self._cache[cache_key][0]
            return self._get_fallback_recommendations(user_id)
    
    def _get_fallback_recommendations(self, user_id: int) -> Dict[str, Any]:
        """Резервные рекомендации при недоступности сервиса"""
        return {
            "user_id": user_id,
            "recommendations": [
                {
                    "category": "general",
                    "priority": 1.0,
                    "rank": 1,
                    "suggestions": ["Попробуйте разные разделы приложения"]
                }
            ],
            "count": 1,
            "timestamp": datetime.now().isoformat()
        }
    
    def invalidate_cache(self, user_id: int = None):
        """Очистка кэша"""
        if user_id:
            # Удаляем конкретного пользователя
            keys_to_delete = [k for k in self._cache.keys() if k.startswith(f"{user_id}_")]
            for key in keys_to_delete:
                del self._cache[key]
        else:
            # Очищаем весь кэш
            self._cache.clear()

Пример для Django проекта
python

# services/recommendation.py
import requests
from django.conf import settings
from django.core.cache import cache

class DjangoRecommendationService:
    def __init__(self):
        self.base_url = settings.RECOMMENDATION_SERVICE_URL
    
    def get_for_user(self, user):
        """
        Получение рекомендаций для Django User
        """
        cache_key = f"recommendations_{user.id}"
        
        # Проверяем кэш
        cached = cache.get(cache_key)
        if cached:
            return cached
        
        try:
            response = requests.get(
                f"{self.base_url}/recommend/{user.id}",
                timeout=2
            )
            
            if response.status_code == 200:
                data = response.json()
                # Кэшируем на 5 минут
                cache.set(cache_key, data, 300)
                return data
                
        except requests.exceptions.RequestException:
            pass
        
        return None
    
    def process_user_action(self, user, action_type, count=1):
        """
        Пример: отправка действия пользователя
        (обычно это делает Analytics Collector, но можно и напрямую)
        """
        action_data = {
            "user_id": user.id,
            "action": action_type,
            "action_count": count
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/process",
                json=[action_data]
            )
            return response.status_code == 200
        except:
            return False

# В settings.py
RECOMMENDATION_SERVICE_URL = "http://localhost:5000"

# В views.py
from .services.recommendation import DjangoRecommendationService

def user_dashboard_view(request):
    recommendation_service = DjangoRecommendationService()
    recommendations = recommendation_service.get_for_user(request.user)
    
    context = {
        'user': request.user,
        'recommendations': recommendations['recommendations'] if recommendations else [],
    }
    
    return render(request, 'dashboard.html', context)

🐳 Docker развертывание
Dockerfile
dockerfile

FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY recommendation_system.py .

EXPOSE 5000

CMD ["uvicorn", "recommendation_system:app", "--host", "0.0.0.0", "--port", "5000"]

docker-compose.yml (полный стек)
yaml

version: '3.8'

services:
  # Recommendation System
  recommendation-system:
    build: ./recommendation
    container_name: recommendation-system
    ports:
      - "5000:5000"
    environment:
      - PYTHONUNBUFFERED=1
    restart: unless-stopped
    networks:
      - app-network

  # Analytics Collector
  analytics-collector:
    build: ./analytics
    container_name: analytics-collector
    ports:
      - "8000:8000"
    environment:
      - RECOMMENDATION_SERVICE_URL=http://recommendation-system:5000
    depends_on:
      - recommendation-system
    restart: unless-stopped
    networks:
      - app-network

  # Ваш Backend сервис
  backend-service:
    build: ./backend
    container_name: backend-service
    ports:
      - "3000:3000"
    environment:
      - RECOMMENDATION_SERVICE_URL=http://recommendation-system:5000
    depends_on:
      - recommendation-system
    restart: unless-stopped
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

Запуск
bash

# Сборка и запуск
docker-compose up --build

# Только запуск
docker-compose up -d

# Просмотр логов
docker-compose logs -f recommendation-system

# Остановка
docker-compose down

🔍 Отладка и мониторинг
Swagger UI

Документация API доступна по адресу: http://localhost:5000/docs
Проверка состояния
bash

# Health check
curl http://localhost:5000/health

# Проверка конфигурации
curl http://localhost:5000/config

# Проверка профиля пользователя
curl http://localhost:5000/profile/12345

Тестирование API
python

# test_recommendation.py
import requests
import json

def test_recommendation_system():
    base_url = "http://localhost:5000"
    
    # 1. Отправка тестовых действий
    test_actions = [
        {
            "user_id": 1001,
            "action": "chatting_assistant",
            "action_count": 8
        },
        {
            "user_id": 1001,
            "action": "book_search", 
            "action_count": 3
        },
        {
            "user_id": 1002,
            "action": "video_watch",
            "action_count": 12
        }
    ]
    
    print("1. Отправка действий...")
    response = requests.post(f"{base_url}/process", json=test_actions)
    print(f"   Статус: {response.status_code}")
    print(f"   Ответ: {json.dumps(response.json(), indent=2)}")
    
    # 2. Получение рекомендаций
    print("\n2. Получение рекомендаций для пользователя 1001...")
    response = requests.get(f"{base_url}/recommend/1001")
    print(f"   Статус: {response.status_code}")
    data = response.json()
    
    for rec in data["recommendations"]:
        print(f"   - {rec['category']}: {rec['priority']:.1%} (ранг: {rec['rank']})")
        for suggestion in rec["suggestions"]:
            print(f"     * {suggestion}")
    
    # 3. Проверка здоровья
    print("\n3. Проверка здоровья...")
    response = requests.get(f"{base_url}/health")
    print(f"   Статус: {response.json()['status']}")

if __name__ == "__main__":
    test_recommendation_system()

Логирование

Система логирует:

    Обработку действий (количество, пользователи)

    Ошибки при обработке

    Запросы на рекомендации

⚠️ Важные моменты
Производительность

    Сервис хранит данные в памяти (in-memory)

    Для продакшена рекомендуется добавить Redis

    Максимальное количество пользователей зависит от доступной RAM

Масштабирование

    Каждый экземпляр независим

    Можно запускать несколько инстансов за балансировщиком

    Нет общей базы данных между инстансами

Безопасность

    API доступен без аутентификации (настройте в продакшене)

    Валидация входных данных через Pydantic

    Ограничение размера запросов

Рекомендации для продакшена

    Добавьте Redis для хранения данных

    Настройте аутентификацию между сервисами

    Добавьте мониторинг и алертинг

    Настройте rate limiting

    Используйте HTTPS

📞 Контакты и поддержка

При возникновении проблем:

    Проверьте логи сервиса

    Проверьте доступность через /health

    Проверьте конфигурацию через /config

    Используйте Swagger UI для тестирования API

Система готова к интеграции! 🚀

Начните с настройки FRONTEND_TO_CATEGORY и протестируйте API через Swagger UI.
