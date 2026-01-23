T2 Intelligence Assistant API Документация
📋 Оглавление

    Общее описание

    Быстрый старт

    API Endpoints

        Analytics Collector

        Recommendation System

    Примеры использования

        Frontend Developer

        Backend Developer

    WebSocket API

    Модели данных

    Обработка ошибок

    Тестирование API

🚀 Общее описание

T2 Intelligence Assistant состоит из двух микросервисов:

    Analytics Collector (порт 8000) - сбор действий пользователей

    Recommendation System (порт 5000) - генерация рекомендаций

Схема работы
text

Frontend → Analytics Collector (WebSocket) → Recommendation System → Backend
      ↑                                         ↓
      └────── Получение рекомендаций ←─────────┘

🎯 Быстрый старт
Локальный запуск
bash

# Клонирование проекта
git clone <repository-url>
cd t2-intelligence-assistant

# Запуск сервисов
docker-compose up --build

Сервисы будут доступны по адресам:

    Analytics Collector: http://localhost:8000

    Recommendation System: http://localhost:5000

Swagger документация

    Analytics Collector: http://localhost:8000/docs

    Recommendation System: http://localhost:5000/docs

📡 API Endpoints
Analytics Collector
1. WebSocket соединение
text

ws://localhost:8000/ws/analytics/{client_id}

Назначение: Отправка действий пользователя в реальном времени

Параметры пути:

    client_id - уникальный идентификатор клиента (строка)

2. Получение статистики пользователя
text

GET /stats/{user_id}

Назначение: Получение статистики действий пользователя

Параметры пути:

    user_id - идентификатор пользователя (строка)

Пример ответа:
json

{
  "user_id": "123",
  "total_actions": 45,
  "action_types": {
    "chatting_assistant": 20,
    "search_books": 15,
    "watch_videos": 10
  },
  "last_action": "2024-01-22T10:30:45"
}

3. Проверка здоровья сервиса
text

GET /health

Ответ:
json

{
  "status": "healthy",
  "timestamp": "2024-01-22T10:30:45",
  "connections": 5,
  "redis": "connected",
  "service": "analytics-collector"
}

Recommendation System
1. Получение рекомендаций
text

GET /recommend/enhanced/{user_id}

Назначение: Получение персонализированных рекомендаций

Параметры пути:

    user_id - идентификатор пользователя (число)

Query параметры:

    context (опционально) - JSON строка с контекстом

Пример запроса:
text

GET /recommend/enhanced/123?context={"time_of_day":"morning","user_preferences":{"preferred_categories":["education"]}}

Пример ответа:
json

{
  "user_id": 123,
  "timestamp": "2024-01-22T10:30:45",
  "context_used": true,
  "recommendations": [
    {
      "category": "education",
      "priority": 0.85,
      "confidence": 0.9,
      "reason": "Ваша активность в обучении высока (85% активности)",
      "suggested_actions": ["Новые курсы", "Статьи по теме", "Вебинары"]
    },
    {
      "category": "chat",
      "priority": 0.15,
      "confidence": 0.7,
      "reason": "Вы активно общаетесь с ассистентом (15% активности)",
      "suggested_actions": ["Задать новый вопрос", "Продолжить диалог"]
    }
  ]
}

2. Пакетная обработка действий
text

POST /process/batch

Назначение: Пакетная обработка действий от analytics collector (используется внутренне)

Тело запроса:
json

[
  {
    "user_id": 123,
    "action_type": "chatting_assistant",
    "action_count": 5,
    "timestamp": "2024-01-22T10:30:45"
  },
  {
    "user_id": 123,
    "action_type": "search_books",
    "action_count": 3,
    "timestamp": "2024-01-22T10:31:00"
  }
]

3. Получение профиля пользователя
text

GET /profile/{user_id}

Ответ:
json

{
  "user_id": 123,
  "profile": {
    "chat": 45.2,
    "education": 32.1,
    "software": 12.5
  },
  "last_updated": "2024-01-22T10:30:45"
}

4. Удаление профиля пользователя
text

DELETE /profile/{user_id}

5. Проверка здоровья
text

GET /health

text

GET /health/redis

👨‍💻 Примеры использования
Frontend Developer
1. Подключение WebSocket для отправки действий
javascript

// Создание WebSocket соединения
const clientId = `user_${Date.now()}`;
const ws = new WebSocket(`ws://localhost:8000/ws/analytics/${clientId}`);

// Обработчик открытия соединения
ws.onopen = () => {
  console.log('WebSocket соединение установлено');
};

// Отправка действия пользователя
function sendUserAction(userId, actionType) {
  const action = {
    user_id: userId,
    action: actionType
  };
  
  ws.send(JSON.stringify(action));
}

// Пример использования
sendUserAction('user123', 'chatting_assistant');
sendUserAction('user123', 'search_books');

// Обработка ответов от сервера
ws.onmessage = (event) => {
  const response = JSON.parse(event.data);
  console.log('Ответ от сервера:', response);
};

// Обработка ошибок
ws.onerror = (error) => {
  console.error('WebSocket ошибка:', error);
};

2. Получение рекомендаций для пользователя
javascript

async function getRecommendations(userId, context = {}) {
  try {
    const contextStr = JSON.stringify(context);
    const url = `http://localhost:5000/recommend/enhanced/${userId}?context=${encodeURIComponent(contextStr)}`;
    
    const response = await fetch(url);
    const data = await response.json();
    
    if (response.ok) {
      return data.recommendations;
    } else {
      console.error('Ошибка получения рекомендаций:', data);
      return [];
    }
  } catch (error) {
    console.error('Ошибка запроса:', error);
    return [];
  }
}

// Пример использования
const recommendations = await getRecommendations(123, {
  time_of_day: 'morning',
  user_preferences: {
    preferred_categories: ['education', 'software']
  }
});

// Отображение рекомендаций
recommendations.forEach(rec => {
  console.log(`${rec.category}: ${rec.reason}`);
  console.log('Предлагаемые действия:', rec.suggested_actions);
});

Backend Developer
1. Интеграция с Analytics Collector
python

import asyncio
import websockets
import json

async def track_user_action(user_id: str, action: str):
    """
    Отправка действия пользователя через WebSocket
    """
    uri = f"ws://localhost:8000/ws/analytics/{user_id}"
    
    try:
        async with websockets.connect(uri) as websocket:
            action_data = {
                "user_id": user_id,
                "action": action
            }
            
            await websocket.send(json.dumps(action_data))
            
            # Получение подтверждения
            response = await websocket.recv()
            response_data = json.loads(response)
            
            if response_data["status"] == "success":
                print(f"Дейтие успешно отправлено: {action}")
            else:
                print(f"Ошибка: {response_data['message']}")
                
    except Exception as e:
        print(f"Ошибка подключения к WebSocket: {e}")

# Пример использования
asyncio.run(track_user_action("user123", "use_function_x"))

2. Получение статистики пользователя
python

import requests

def get_user_stats(user_id: str):
    """
    Получение статистики действий пользователя
    """
    url = f"http://localhost:8000/stats/{user_id}"
    
    try:
        response = requests.get(url)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Ошибка: {response.status_code}")
            return None
    except requests.exceptions.RequestException as e:
        print(f"Ошибка запроса: {e}")
        return None

# Пример использования
stats = get_user_stats("user123")
if stats:
    print(f"Всего действий: {stats['total_actions']}")
    print(f"Типы действий: {stats['action_types']}")

3. Интеграция с Recommendation System
python

import requests
import json

class RecommendationClient:
    def __init__(self, base_url="http://localhost:5000"):
        self.base_url = base_url
    
    def get_recommendations(self, user_id: int, context: dict = None):
        """
        Получение рекомендаций для пользователя
        """
        url = f"{self.base_url}/recommend/enhanced/{user_id}"
        
        params = {}
        if context:
            params['context'] = json.dumps(context)
        
        try:
            response = requests.get(url, params=params)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Ошибка получения рекомендаций: {e}")
            return None
    
    def get_user_profile(self, user_id: int):
        """
        Получение профиля пользователя
        """
        url = f"{self.base_url}/profile/{user_id}"
        
        try:
            response = requests.get(url)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Ошибка получения профиля: {e}")
            return None

# Пример использования
client = RecommendationClient()

# Получение рекомендаций с контекстом
context = {
    "time_of_day": "evening",
    "user_preferences": {
        "preferred_categories": ["chat", "entertainment"]
    }
}

recommendations = client.get_recommendations(123, context)
if recommendations:
    print(f"Рекомендации для пользователя {recommendations['user_id']}:")
    for rec in recommendations['recommendations']:
        print(f"- {rec['category']}: {rec['reason']} (приоритет: {rec['priority']})")

🔌 WebSocket API
Формат сообщений
Отправка действия (Frontend → Analytics Collector)
json

{
  "user_id": "string",
  "action": "string"
}

Поддерживаемые действия:

    chatting_assistant - общение с ассистентом

    search_books - поиск книг

    watch_videos - просмотр видео

    read_articles - чтение статей

    use_function_x - использование функции X

    Любые другие пользовательские действия

Ответ сервера
json

{
  "status": "success" | "error",
  "message": "string",
  "timestamp": "ISO 8601 string"
}

Пример полного цикла WebSocket
javascript

const ws = new WebSocket('ws://localhost:8000/ws/analytics/frontend_app');

// Подписка на события
ws.addEventListener('open', () => {
  console.log('Connected to analytics service');
  
  // Отправка тестового действия
  ws.send(JSON.stringify({
    user_id: 'user_123',
    action: 'chatting_assistant'
  }));
});

ws.addEventListener('message', (event) => {
  const data = JSON.parse(event.data);
  console.log('Received:', data);
  
  if (data.status === 'success') {
    console.log('Action processed successfully');
  } else {
    console.error('Error:', data.message);
  }
});

ws.addEventListener('error', (error) => {
  console.error('WebSocket error:', error);
});

ws.addEventListener('close', () => {
  console.log('Connection closed');
});

📊 Модели данных
Действие пользователя (Analytics Collector)
json

{
  "user_id": "string",
  "action": "string"
}

Действие для обработки (Recommendation System)
json

{
  "user_id": "integer",
  "action_type": "string",
  "action_count": "integer",
  "timestamp": "string"
}

Рекомендация
json

{
  "category": "string",
  "priority": "float",
  "confidence": "float",
  "reason": "string",
  "suggested_actions": ["string"]
}

Контекст для рекомендаций
json

{
  "time_of_day": "string",  // "morning", "afternoon", "evening"
  "user_preferences": {
    "preferred_categories": ["string"]
  }
}

⚠️ Обработка ошибок
Коды состояния HTTP
Analytics Collector

    200 - Успешный запрос

    400 - Неверный формат данных

    404 - Ресурс не найден

    500 - Внутренняя ошибка сервера

Recommendation System

    200 - Успешный запрос

    400 - Неверный формат данных или контекста

    404 - Профиль пользователя не найден

    500 - Внутренняя ошибка сервера

WebSocket ошибки
json

{
  "status": "error",
  "message": "Описание ошибки"
}

Возможные ошибки:

    "Невалидный JSON" - неверный формат JSON

    "user_id is required" - отсутствует user_id

    "action is required" - отсутствует действие

    "Внутренняя ошибка сервера" - серверная ошибка

🧪 Тестирование API
Использование cURL
1. Проверка здоровья сервисов
bash

# Analytics Collector
curl http://localhost:8000/health

# Recommendation System
curl http://localhost:5000/health
curl http://localhost:5000/health/redis

2. Получение рекомендаций
bash

# Без контекста
curl http://localhost:5000/recommend/enhanced/123

# С контекстом
curl "http://localhost:5000/recommend/enhanced/123?context=%7B%22time_of_day%22%3A%22morning%22%7D"

3. Получение статистики
bash

curl http://localhost:8000/stats/user123

Использование Python для тестирования
python

import requests
import json

def test_analytics_collector():
    """Тестирование Analytics Collector"""
    print("Testing Analytics Collector...")
    
    # Проверка здоровья
    health = requests.get("http://localhost:8000/health").json()
    print(f"Health: {health['status']}")
    
    # Получение статистики
    stats = requests.get("http://localhost:8000/stats/test_user").json()
    print(f"Stats: {stats}")
    
    return health['status'] == 'healthy'

def test_recommendation_system():
    """Тестирование Recommendation System"""
    print("\nTesting Recommendation System...")
    
    # Проверка здоровья
    health = requests.get("http://localhost:5000/health").json()
    print(f"Health: {health['status']}")
    
    # Получение рекомендаций
    recs = requests.get("http://localhost:5000/recommend/enhanced/1").json()
    print(f"Recommendations: {len(recs['recommendations'])} items")
    
    return health['status'] == 'healthy'

if __name__ == "__main__":
    if test_analytics_collector() and test_recommendation_system():
        print("\n✅ Все тесты пройдены успешно!")
    else:
        print("\n❌ Некоторые тесты не пройдены")

Использование Postman
Коллекция для Analytics Collector

    GET {{base_url}}/health

    GET {{base_url}}/stats/{{user_id}}

    WebSocket ws://{{host}}:8000/ws/analytics/{{client_id}}

Коллекция для Recommendation System

    GET {{base_url}}/health

    GET {{base_url}}/recommend/enhanced/{{user_id}}

    GET {{base_url}}/profile/{{user_id}}

    DELETE {{base_url}}/profile/{{user_id}}

📝 Важные заметки
Для Frontend разработчиков

    Всегда используйте try-catch при работе с WebSocket

    Реализуйте повторное подключение при разрыве соединения

    Кэшируйте рекомендации на клиенте для уменьшения запросов

    Отправляйте действия пользователя в реальном времени

Для Backend разработчиков

    Реализуйте кэширование рекомендаций на бэкенде

    Обрабатывайте временную недоступность сервисов

    Используйте асинхронные вызовы для работы с API

    Реализуйте механизм повторных попыток при ошибках

Общие рекомендации

    Мониторинг: Регулярно проверяйте /health эндпоинты

    Логирование: Все ошибки логируются в соответствующие файлы

    Производительность: WebSocket обеспечивает минимальную задержку

    Масштабируемость: Сервисы спроектированы для горизонтального масштабирования

🔗 Полезные ссылки

    Swagger документация Analytics Collector

    Swagger документация Recommendation System

    WebSocket RFC

    Docker документация

Поддержка: При возникновении вопросов обращайтесь к команде разработки или создавайте issue в репозитории проекта.