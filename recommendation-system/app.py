"""
Основной файл приложения Recommendation System
Объединяет все модули и запускает сервер
"""

import logging
from flask import Flask
from flask_restx import Api
from .recommendation_engine import EnhancedRecommendationSystem
from .redis_manager import RedisManager
from .routes import (
    ProcessBatchResource,
    EnhancedRecommendationsResource,
    UserProfileResource,
    RedisHealthResource,
    SystemHealthResource
)

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('recommendation.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Создание Flask приложения
app = Flask(__name__)
app.config['JSON_SORT_KEYS'] = False
app.config['ERROR_404_HELP'] = False

# Создание API
api = Api(
    app, 
    version='2.0', 
    title='Enhanced Recommendation Engine',
    description='Улучшенная система рекомендаций с поддержкой аналитики',
    doc='/docs',
    default='Recommendation System',
    default_label='API для рекомендаций'
)

# Инициализация менеджеров
redis_manager = RedisManager(host="redis", port=6379)
rec_system = EnhancedRecommendationSystem(redis_manager)

# Сохранение в конфиг приложения для доступа из ресурсов
app.config['REDIS_MANAGER'] = redis_manager
app.config['RECOMMENDATION_SYSTEM'] = rec_system

# Регистрация ресурсов
api.add_resource(ProcessBatchResource, '/process/batch')
api.add_resource(EnhancedRecommendationsResource, '/recommend/enhanced/<int:user_id>')
api.add_resource(UserProfileResource, '/profile/<int:user_id>')
api.add_resource(RedisHealthResource, '/health/redis')
api.add_resource(SystemHealthResource, '/health')


@app.before_first_request
def initialize_services():
    """
    Инициализация сервисов перед первым запросом
    """
    try:
        logger.info("Initializing recommendation system services...")
        
        # Подключение к Redis
        redis_manager.connect()
        logger.info("Redis manager initialized")
        
        logger.info("Recommendation system services initialized successfully")
        
    except Exception as e:
        logger.error(f"Failed to initialize services: {str(e)}", exc_info=True)
        raise


@app.teardown_appcontext
def shutdown_services(exception=None):
    """
    Завершение работы сервисов при остановке приложения
    """
    try:
        logger.info("Shutting down recommendation system services...")
        
        # Закрытие Redis соединения
        redis_manager.close()
        logger.info("Redis connection closed")
        
        logger.info("Recommendation system services shutdown complete")
        
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}", exc_info=True)


@app.errorhandler(404)
def not_found(error):
    """
    Обработчик для 404 ошибок
    """
    logger.warning(f"404 error: {str(error)}")
    return {'error': 'Resource not found'}, 404


@app.errorhandler(500)
def internal_error(error):
    """
    Обработчик для 500 ошибок
    """
    logger.error(f"500 error: {str(error)}", exc_info=True)
    return {'error': 'Internal server error'}, 500


if __name__ == '__main__':
    """
    Точка входа для запуска сервера напрямую
    """
    try:
        # Инициализация сервисов перед запуском
        initialize_services()
        
        # Запуск сервера
        app.run(
            host='0.0.0.0',
            port=5000,
            debug=False,  # В продакшене debug=False
            threaded=True
        )
    except Exception as e:
        logger.error(f"Failed to start server: {str(e)}", exc_info=True)
        raise