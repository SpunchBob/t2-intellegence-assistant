import logging
from flask import Flask, g
from flask_restx import Api, Resource, fields

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

# Импортируем модули после создания app
import redis_manager
import recommendation_engine
import routes

# Инициализация менеджеров (делаем это лениво)
redis_manager_obj = None
rec_system = None

def get_redis_manager():
    """Ленивая инициализация Redis менеджера"""
    global redis_manager_obj
    if redis_manager_obj is None:
        redis_manager_obj = redis_manager.RedisManager(host="redis", port=6379)
    return redis_manager_obj

def get_rec_system():
    """Ленивая инициализация системы рекомендаций"""
    global rec_system
    if rec_system is None:
        rec_system = recommendation_engine.EnhancedRecommendationSystem(get_redis_manager())
    return rec_system

def initialize_services():
    """Инициализация сервисов"""
    try:
        if not hasattr(g, 'services_initialized'):
            logger.info("Initializing recommendation system services...")
            
            # Инициализируем Redis
            redis_mgr = get_redis_manager()
            redis_mgr.connect()
            logger.info("Redis manager initialized")
            
            # Инициализируем систему рекомендаций
            get_rec_system()
            logger.info("Recommendation system initialized")
            
            g.services_initialized = True
            logger.info("Recommendation system services initialized successfully")
            
    except Exception as e:
        logger.error(f"Failed to initialize services: {str(e)}", exc_info=True)
        raise

# Middleware для инициализации сервисов перед каждым запросом
@app.before_request
def before_request():
    """Инициализация сервисов перед запросом"""
    initialize_services()
    
    # Сохраняем в конфиг приложения для доступа из ресурсов
    app.config['REDIS_MANAGER'] = get_redis_manager()
    app.config['RECOMMENDATION_SYSTEM'] = get_rec_system()

# Определяем модели для Swagger
action_model = api.model('AnalyticsAction', routes.action_fields)
recommendation_model = api.model('EnhancedRecommendation', routes.recommendation_fields)

# Регистрация ресурсов с моделями
@api.route('/process/batch')
class ProcessBatch(Resource):
    @api.expect([action_model])
    def post(self):
        return routes.ProcessBatchResource().post()

@api.route('/recommend/enhanced/<int:user_id>')
class EnhancedRecommendations(Resource):
    @api.doc(params={'context': 'Контекстные данные (JSON)'})
    def get(self, user_id):
        return routes.EnhancedRecommendationsResource().get(user_id)

@api.route('/profile/<int:user_id>')
class UserProfile(Resource):
    def get(self, user_id):
        return routes.UserProfileResource().get(user_id)
    
    def delete(self, user_id):
        return routes.UserProfileResource().delete(user_id)

@api.route('/health/redis')
class RedisHealth(Resource):
    def get(self):
        return routes.RedisHealthResource().get()

@api.route('/health')
class SystemHealth(Resource):
    def get(self):
        return routes.SystemHealthResource().get()

@app.teardown_appcontext
def shutdown_services(exception=None):
    """Завершение работы сервисов при остановке приложения"""
    try:
        if redis_manager_obj:
            logger.info("Shutting down recommendation system services...")
            redis_manager_obj.close()
            logger.info("Redis connection closed")
            logger.info("Recommendation system services shutdown complete")
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}", exc_info=True)

@app.errorhandler(404)
def not_found(error):
    logger.warning(f"404 error: {str(error)}")
    return {'error': 'Resource not found'}, 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"500 error: {str(error)}", exc_info=True)
    return {'error': 'Internal server error'}, 500

if __name__ == '__main__':
    try:
        # Инициализация сервисов при запуске
        with app.app_context():
            initialize_services()
        
        # Запуск сервера
        app.run(
            host='0.0.0.0',
            port=5000,
            debug=False,
            threaded=True
        )
    except Exception as e:
        logger.error(f"Failed to start server: {str(e)}", exc_info=True)
        raise
