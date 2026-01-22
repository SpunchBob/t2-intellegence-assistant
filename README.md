📱 Analytics Collector API - Руководство для Frontend разработчика
🎯 О сервисе

Analytics Collector API - это сервис для сбора аналитики пользовательских действий с мобильного приложения. Сервис принимает данные через WebSocket, агрегирует их и отправляет в систему рекомендаций.
🚀 Быстрый старт
1. Запуск сервиса
bash

# Установите зависимости
pip install fastapi uvicorn websockets httpx

# Запустите сервис
python app.py

# Сервис будет доступен по адресу:
# API: http://localhost:8000
# WebSocket: ws://localhost:8000/ws/analytics/{client_id}
# Документация: http://localhost:8000/docs

2. Docker (альтернативный способ)
bash

# Запустите Redis и Analytics Collector
docker-compose up -d

# Проверьте статус
docker-compose ps

📡 WebSocket API
Подключение к WebSocket
javascript

const clientId = 'user_123_session_456'; // Уникальный ID клиента/сессии
const ws = new WebSocket(`ws://localhost:8000/ws/analytics/${clientId}`);

Формат отправляемых данных
json

{
  "user_id": "user_123",        // ID пользователя (строка)
  "action": "purchase_view"     // Действие пользователя (строка)
}

Примеры действий
javascript

// Примеры типов действий:
const actions = {
  // Просмотры
  PURCHASE_VIEW: "purchase_view",
  BOOK_SEARCH: "book_search", 
  VIDEO_WATCH: "video_watch",
  ARTICLE_READ: "article_read",
  PROFILE_VIEW: "profile_view",
  
  // Взаимодействия
  BUTTON_CLICK: "button_click",
  TAB_SWITCH: "tab_switch",
  SEARCH: "search_action",
  
  // Покупки
  ADD_TO_CART: "add_to_cart",
  BUY_NOW: "buy_now"
};

🎨 Пример реализации на JavaScript
Простой трекер для веб-приложения
javascript

class AnalyticsTracker {
  constructor() {
    this.ws = null;
    this.userId = this.getOrCreateUserId();
    this.sessionId = this.generateSessionId();
    this.baseUrl = 'ws://localhost:8000';
    this.isConnected = false;
    this.pendingActions = [];
    
    this.init();
  }
  
  // Генерация уникальных ID
  generateSessionId() {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  getOrCreateUserId() {
    // Получаем userId из localStorage или создаем новый
    let userId = localStorage.getItem('analytics_user_id');
    if (!userId) {
      userId = `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      localStorage.setItem('analytics_user_id', userId);
    }
    return userId;
  }
  
  // Инициализация WebSocket
  init() {
    this.connectWebSocket();
    
    // Автоматическое переподключение
    setInterval(() => {
      if (!this.isConnected) {
        this.connectWebSocket();
      }
    }, 5000);
    
    // Автоматическая отправка накопленных действий
    setInterval(() => {
      if (this.pendingActions.length > 0 && this.isConnected) {
        this.sendBatch();
      }
    }, 10000);
  }
  
  connectWebSocket() {
    const wsUrl = `${this.baseUrl}/ws/analytics/${this.sessionId}`;
    this.ws = new WebSocket(wsUrl);
    
    this.ws.onopen = () => {
      console.log('✅ Подключено к Analytics Collector');
      this.isConnected = true;
      
      // Отправляем накопленные действия
      if (this.pendingActions.length > 0) {
        this.sendBatch();
      }
    };
    
    this.ws.onmessage = (event) => {
      const response = JSON.parse(event.data);
      console.log('📨 Ответ от сервера:', response);
    };
    
    this.ws.onerror = (error) => {
      console.error('❌ WebSocket ошибка:', error);
      this.isConnected = false;
    };
    
    this.ws.onclose = () => {
      console.log('🔌 WebSocket соединение закрыто');
      this.isConnected = false;
    };
  }
  
  // Трекинг действия
  track(action, metadata = {}) {
    const actionData = {
      user_id: this.userId,
      action: action,
      ...metadata
    };
    
    this.pendingActions.push(actionData);
    
    // Если накопилось много действий или действие важное - отправляем сразу
    if (this.pendingActions.length >= 5 || action.includes('purchase')) {
      this.sendBatch();
    }
    
    return actionData;
  }
  
  // Отправка батча действий
  sendBatch() {
    if (!this.isConnected || this.pendingActions.length === 0) {
      return;
    }
    
    const batch = [...this.pendingActions];
    this.pendingActions = [];
    
    this.ws.send(JSON.stringify(batch));
    console.log(`📤 Отправлен батч из ${batch.length} действий`);
  }
  
  // Ручная отправка
  sendNow() {
    this.sendBatch();
  }
  
  // Получение статистики (опционально)
  async getStats() {
    try {
      const response = await fetch(`http://localhost:8000/stats/${this.userId}`);
      return await response.json();
    } catch (error) {
      console.error('Ошибка получения статистики:', error);
      return null;
    }
  }
}

// Создание экземпляра трекера
const tracker = new AnalyticsTracker();

📱 Пример для React Native
javascript

// analyticsTracker.js
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

class MobileAnalyticsTracker {
  constructor() {
    this.ws = null;
    this.userId = null;
    this.sessionId = null;
    this.baseUrl = Platform.OS === 'android' 
      ? 'ws://10.0.2.2:8000'  // Android эмулятор
      : 'ws://localhost:8000'; // iOS симулятор
    this.pendingActions = [];
    
    this.init();
  }
  
  async init() {
    await this.getOrCreateUserId();
    this.sessionId = this.generateSessionId();
    this.connectWebSocket();
  }
  
  generateSessionId() {
    return `mobile_session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  async getOrCreateUserId() {
    try {
      let userId = await AsyncStorage.getItem('analytics_user_id');
      if (!userId) {
        userId = `mobile_user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        await AsyncStorage.setItem('analytics_user_id', userId);
      }
      this.userId = userId;
    } catch (error) {
      console.error('Ошибка получения userId:', error);
      this.userId = `temp_user_${Date.now()}`;
    }
  }
  
  connectWebSocket() {
    const wsUrl = `${this.baseUrl}/ws/analytics/${this.sessionId}`;
    this.ws = new WebSocket(wsUrl);
    
    this.ws.onopen = () => {
      console.log('WebSocket подключен');
      this.sendPendingActions();
    };
    
    this.ws.onmessage = (event) => {
      console.log('Получен ответ:', JSON.parse(event.data));
    };
    
    this.ws.onerror = (error) => {
      console.error('WebSocket ошибка:', error);
    };
    
    this.ws.onclose = () => {
      console.log('WebSocket соединение закрыто');
      setTimeout(() => this.connectWebSocket(), 5000);
    };
  }
  
  // Трекинг действия
  track(action, metadata = {}) {
    const actionData = {
      user_id: this.userId,
      action: action,
      timestamp: new Date().toISOString(),
      platform: Platform.OS,
      ...metadata
    };
    
    this.pendingActions.push(actionData);
    
    // Если WebSocket подключен - отправляем сразу
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.sendAction(actionData);
    }
    
    return actionData;
  }
  
  sendAction(action) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(action));
    }
  }
  
  sendPendingActions() {
    if (this.pendingActions.length > 0 && this.ws.readyState === WebSocket.OPEN) {
      this.pendingActions.forEach(action => this.sendAction(action));
      this.pendingActions = [];
    }
  }
  
  // Примеры типовых событий
  trackScreenView(screenName) {
    this.track('screen_view', { screen: screenName });
  }
  
  trackButtonClick(buttonName) {
    this.track('button_click', { button: buttonName });
  }
  
  trackPurchase(productId, amount) {
    this.track('purchase_complete', { 
      product_id: productId, 
      amount: amount 
    });
  }
}

export default new MobileAnalyticsTracker();

📊 Использование в React Native компонентах
javascript

// App.js
import React, { useEffect } from 'react';
import { Button, View, Text } from 'react-native';
import analytics from './analyticsTracker';

function App() {
  useEffect(() => {
    // Трекинг открытия приложения
    analytics.track('app_open', { 
      version: '1.0.0',
      timestamp: new Date().toISOString()
    });
  }, []);

  return (
    <View>
      <Button
        title="Посмотреть товары"
        onPress={() => {
          analytics.track('purchase_view');
          // Навигация к товарам
        }}
      />
      
      <Button
        title="Поиск книг"
        onPress={() => {
          analytics.track('book_search');
          // Открытие поиска
        }}
      />
      
      <Button
        title="Купить"
        onPress={() => {
          analytics.track('buy_now', { 
            product_id: '123', 
            price: 99.99 
          });
          // Логика покупки
        }}
      />
    </View>
  );
}

🔧 Настройки подключения
Для разработки:

    Локально: ws://localhost:8000/ws/analytics/{client_id}

    В сети: ws://{ваш-ip}:8000/ws/analytics/{client_id}

Для продакшена:
javascript

// config.js
export const ANALYTICS_CONFIG = {
  development: {
    wsUrl: 'ws://localhost:8000/ws/analytics'
  },
  production: {
    wsUrl: 'wss://your-domain.com/ws/analytics'  // HTTPS для продакшена
  }
};

📈 Примеры отправляемых данных
Базовое действие:
json

{
  "user_id": "user_abc123",
  "action": "purchase_view"
}

Действие с дополнительными данными:
json

{
  "user_id": "user_abc123",
  "action": "product_click",
  "product_id": "prod_789",
  "category": "electronics",
  "price": 299.99
}

Батч действий:
json

[
  {
    "user_id": "user_abc123",
    "action": "screen_view",
    "screen": "home"
  },
  {
    "user_id": "user_abc123", 
    "action": "button_click",
    "button": "search"
  },
  {
    "user_id": "user_abc123",
    "action": "search",
    "query": "новые книги"
  }
]

⚠️ Обработка ошибок
Проверка подключения:
javascript

// Проверка статуса сервиса
async function checkServiceStatus() {
  try {
    const response = await fetch('http://localhost:8000/health');
    const data = await response.json();
    console.log('Статус сервиса:', data);
    return data.status === 'healthy';
  } catch (error) {
    console.error('Сервис недоступен:', error);
    return false;
  }
}

// Локальное хранение при отсутствии соединения
function saveActionLocally(action) {
  const pendingActions = JSON.parse(localStorage.getItem('pending_actions') || '[]');
  pendingActions.push({
    ...action,
    timestamp: new Date().toISOString()
  });
  localStorage.setItem('pending_actions', JSON.stringify(pendingActions));
  
  // Пытаемся отправить при восстановлении соединения
  window.addEventListener('online', () => {
    sendPendingActions();
  });
}

🛠️ Утилиты для разработки
Тестовый клиент:
html

<!-- test_client.html -->
<!DOCTYPE html>
<html>
<body>
  <h2>Тест Analytics Collector</h2>
  
  <div>
    <input type="text" id="userId" placeholder="User ID" value="test_user_123">
    <input type="text" id="action" placeholder="Action" value="test_action">
    <button onclick="sendAction()">Отправить действие</button>
  </div>
  
  <div id="status">Статус: Не подключен</div>
  <div id="log"></div>

  <script>
    let ws = null;
    
    function connect() {
      const clientId = 'test_client_' + Date.now();
      ws = new WebSocket(`ws://localhost:8000/ws/analytics/${clientId}`);
      
      ws.onopen = () => {
        document.getElementById('status').textContent = 'Статус: Подключен';
      };
      
      ws.onmessage = (event) => {
        const log = document.getElementById('log');
        log.innerHTML = `<div>${new Date().toLocaleTimeString()}: ${event.data}</div>` + log.innerHTML;
      };
      
      ws.onerror = (error) => {
        document.getElementById('status').textContent = 'Статус: Ошибка';
        console.error(error);
      };
    }
    
    function sendAction() {
      if (!ws || ws.readyState !== WebSocket.OPEN) {
        alert('Сначала подключитесь!');
        connect();
        return;
      }
      
      const action = {
        user_id: document.getElementById('userId').value,
        action: document.getElementById('action').value
      };
      
      ws.send(JSON.stringify(action));
    }
    
    // Автоподключение при загрузке
    connect();
  </script>
</body>
</html>

📋 Checklist для интеграции

    Добавить трекер аналитики в проект

    Настроить отправку основных действий (просмотры, клики)

    Реализовать уникальные ID пользователя и сессии

    Добавить обработку ошибок и реконнект

    Протестировать подключение к локальному серверу

    Настроить окружение для продакшена

❓ Частые вопросы

Q: Что делать если WebSocket не подключается?
A: Проверьте:

    Запущен ли сервис (python app.py)

    Правильный ли адрес (localhost:8000)

    Не блокирует ли фаервол соединение

Q: Как тестировать на реальном устройстве?
A: Используйте IP адрес компьютера вместо localhost и убедитесь, что устройства в одной сети.

Q: Куда отправляются данные после обработки?
A: Данные агрегируются и отправляются в Recommendation Engine для формирования персонализированных рекомендаций.
📞 Контакты

При возникновении проблем или вопросов по интеграции обращайтесь к backend разработчику.

Счастливого трекинга! 🚀
