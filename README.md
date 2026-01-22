Recommendation System API
<div align="center">

https://img.shields.io/badge/Python-3.9%252B-blue
https://img.shields.io/badge/Flask-2.3%252B-green
https://img.shields.io/badge/Docker-ready-blue
https://img.shields.io/badge/REST%2520API-%E2%9C%94-success
https://img.shields.io/badge/Swagger%2520UI-included-orange

Модуль рекомендательной системы на основе анализа действий пользователей.
</div>
📋 Оглавление

    🚀 Быстрый старт

    🎯 Основные возможности

    🏗️ Архитектура

    📡 API Endpoints

    🔧 Конфигурация

    🐳 Docker развертывание

    🧪 Тестирование

    📊 Примеры использования

    🔍 Взаимодействие с Backend

    🔄 Расширение системы

    📝 Лицензия

🚀 Быстрый старт
Вариант 1: Запуск через Docker Compose (рекомендуется)
bash

# Скачайте файлы проекта
# Запустите сборку и запуск
docker-compose up --build

# Система будет доступна по адресу:
# API: http://localhost:5000
# Swagger UI: http://localhost:5000/swagger/

Вариант 2: Локальная установка
bash

# Установите зависимости
pip install -r requirements.txt

# Запустите приложение
python app_enhanced.py

# Или с использованием gunicorn для продакшена
gunicorn --bind 0.0.0.0:5000 app:app --workers 4

🎯 Основные возможности

    ✅ Обработка пользовательских действий в реальном времени

    ✅ Автоматическая категоризация действий

    ✅ Персонализированные рекомендации на основе поведения

    ✅ RESTful API для легкой интеграции

    ✅ Swagger UI для интерактивной документации и тестирования

    ✅ Docker-контейнеризация для простого развертывания

    ✅ Масштабируемая архитектура с поддержкой Redis

    ✅ Мониторинг здоровья системы