import logging
import sys
import os
from flask import Flask, g
from flask_restx import Api, Resource, fields

# Добавляем текущую директорию в путь для импортов
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

logger = logging.getLogger(__name__)

# Создание Flask приложения
app = Flask(__name__)
app.config['JSON_SORT_KEYS'] = False
app.config['ERROR_404_HELP'] = False
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = False  # Отключаем pretty print для чистого JSON

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
try:
    from redis_manager import RedisManager
    from recommendation_engine import EnhancedRecommendationSystem
    import routes
    logger.info("Successfully imported all modules")
except ImportError as e:
    logger.error(f"Import error: {str(e)}")
    raise

# Инициализация менеджеров (делаем это лениво)
redis_manager_obj = None
rec_system = None

def get_redis_manager():
    """Ленивая инициализация Redis менеджера"""
    global redis_manager_obj
    if redis_manager_obj is None:
        try:
            redis_manager_obj = RedisManager(host="redis", port=6379)
            logger.info("RedisManager created")
        except Exception as e:
            logger.error(f"Failed to create RedisManager: {str(e)}")
            raise
    return redis_manager_obj

def get_rec_system():
    """Ленивая инициализация системы рекомендаций"""
    global rec_system
    if rec_system is None:
        try:
            rec_system = EnhancedRecommendationSystem(get_redis_manager())
            logger.info("EnhancedRecommendationSystem created")
        except Exception as e:
            logger.error(f"Failed to create EnhancedRecommendationSystem: {str(e)}")
            raise
    return rec_system

def initialize_services():
    """Инициализация сервисов"""
    try:
        if not hasattr(g, 'services_initialized'):
            logger.info("Initializing recommendation system services...")
            
            # Инициализируем Redis
            redis_mgr = get_redis_manager()
            if redis_mgr.connect():
                logger.info("Redis manager connected successfully")
            else:
                logger.warning("Redis connection failed, using fallback mode")
            
            # Инициализируем систему рекомендаций
            get_rec_system()
            logger.info("Recommendation system initialized")
            
            g.services_initialized = True
            logger.info("Recommendation system services initialized successfully")
            
    except Exception as e:
        logger.error(f"Failed to initialize services: {str(e)}", exc_info=True)
        # Не падаем полностью, пытаемся работать в fallback режиме
        g.services_initialized = True

# Middleware для инициализации сервисов перед каждым запросом
@app.before_request
def before_request():
    """Инициализация сервисов перед запросом"""
    try:
        initialize_services()
        
        # Сохраняем в конфиг приложения для доступа из ресурсов
        app.config['REDIS_MANAGER'] = get_redis_manager()
        app.config['RECOMMENDATION_SYSTEM'] = get_rec_system()
    except Exception as e:
        logger.error(f"Error in before_request: {str(e)}")
        # Продолжаем выполнение, некоторые функции могут работать без сервисов

# Определяем модели для Swagger из routes
try:
    action_model = api.model('AnalyticsAction', routes.action_fields)
    recommendation_model = api.model('EnhancedRecommendation', routes.recommendation_fields)
except Exception as e:
    logger.error(f"Failed to create Swagger models: {str(e)}")
    # Создаем простые модели как fallback
    action_model = api.model('AnalyticsAction', {})
    recommendation_model = api.model('EnhancedRecommendation', {})

# Модель для BestCategoryDTO для Swagger
best_category_model = api.model('BestCategoryDTO', {
    'Id': fields.Integer(required=True, description='Идентификатор пользователя'),
    'BestCategorytName': fields.String(description='Название лучшей категории', default='general')
})

# Регистрация ресурсов с моделями
@api.route('/process/batch')
class ProcessBatch(Resource):
    @api.expect(api.model('BatchRequest', {
        'actions': fields.List(fields.Raw, required=True, description='Список действий')
    }))
    def post(self):
        """Обработка пакета действий"""
        try:
            return routes.ProcessBatchResource().post()
        except Exception as e:
            logger.error(f"Error in ProcessBatch: {str(e)}", exc_info=True)
            return {'error': 'Internal server error'}, 500

@api.route('/recommend/enhanced/<int:user_id>')
@api.param('user_id', 'Идентификатор пользователя')
class EnhancedRecommendations(Resource):
    @api.doc(params={'context': 'Контекстные данные (JSON строка)'})
    def get(self, user_id):
        """Получение расширенных рекомендаций для пользователя"""
        try:
            return routes.EnhancedRecommendationsResource().get(user_id)
        except Exception as e:
            logger.error(f"Error in EnhancedRecommendations: {str(e)}", exc_info=True)
            return {'error': 'Internal server error'}, 500

@api.route('/profile/<int:user_id>')
@api.param('user_id', 'Идентификатор пользователя')
class UserProfile(Resource):
    def get(self, user_id):
        """Получение профиля пользователя"""
        try:
            return routes.UserProfileResource().get(user_id)
        except Exception as e:
            logger.error(f"Error in UserProfile GET: {str(e)}", exc_info=True)
            return {'error': 'Internal server error'}, 500
    
    def delete(self, user_id):
        """Удаление профиля пользователя"""
        try:
            return routes.UserProfileResource().delete(user_id)
        except Exception as e:
            logger.error(f"Error in UserProfile DELETE: {str(e)}", exc_info=True)
            return {'error': 'Internal server error'}, 500

@api.route('/health/redis')
class RedisHealth(Resource):
    def get(self):
        """Проверка состояния Redis"""
        try:
            return routes.RedisHealthResource().get()
        except Exception as e:
            logger.error(f"Error in RedisHealth: {str(e)}", exc_info=True)
            return {'redis': 'error', 'error': str(e)}, 500

@api.route('/health')
class SystemHealth(Resource):
    def get(self):
        """Проверка общего состояния системы"""
        try:
            return routes.SystemHealthResource().get()
        except Exception as e:
            logger.error(f"Error in SystemHealth: {str(e)}", exc_info=True)
            return {'status': 'error', 'error': str(e)}, 500

# Новый эндпоинт для .NET DTO - основная функция для вашего случая
@api.route('/recommend/best-category/<int:user_id>')
@api.param('user_id', 'Идентификатор пользователя')
class BestCategoryRecommendation(Resource):
    @api.marshal_with(best_category_model)
    @api.response(200, 'Success', best_category_model)
    @api.response(500, 'Internal Server Error')
    def get(self, user_id):
        """
        Получение лучшей категории для пользователя
        Формат для .NET DTO: {"Id": int, "BestCategorytName": "string"}
        
        Этот эндпоинт специально создан для интеграции с .NET приложением.
        Он возвращает данные в точном формате, ожидаемом C# DTO BestProductDTO.
        """
        try:
            # Проверяем инициализацию сервисов
            rec_system = app.config.get('RECOMMENDATION_SYSTEM')
            
            if not rec_system:
                logger.error("Recommendation system not initialized in config")
                return {
                    'Id': user_id,
                    'BestCategorytName': 'general'
                }, 200  # Возвращаем 200 даже при ошибке, но с дефолтным значением
            
            # Получаем рекомендации
            try:
                recommendations = rec_system.get_enhanced_recommendations(user_id)
            except Exception as e:
                logger.warning(f"Could not get recommendations for user {user_id}: {str(e)}")
                recommendations = []
            
            # Определяем лучшую категорию
            best_category = 'general'  # Категория по умолчанию
            
            if recommendations and isinstance(recommendations, list) and len(recommendations) > 0:
                try:
                    # Ищем рекомендацию с наивысшим приоритетом
                    valid_recs = [r for r in recommendations if isinstance(r, dict) and 'category' in r]
                    if valid_recs:
                        best_recommendation = max(
                            valid_recs, 
                            key=lambda x: float(x.get('priority', 0.0))
                        )
                        best_category = best_recommendation.get('category', 'general')
                        logger.debug(f"Found best category '{best_category}' for user {user_id}")
                except (ValueError, TypeError) as e:
                    logger.warning(f"Error processing recommendations for user {user_id}: {str(e)}")
                    best_category = 'general'
            
            # Формируем ответ точно по DTO
            response = {
                'Id': user_id,
                'BestCategorytName': best_category
            }
            
            logger.info(f"Best category for user {user_id}: {best_category}")
            return response
            
        except Exception as e:
            logger.error(f"Failed to get best category for user {user_id}: {str(e)}", exc_info=True)
            # Даже при ошибке возвращаем корректный DTO с дефолтным значением
            return {
                'Id': user_id,
                'BestCategorytName': 'general'
            }, 200

@app.teardown_appcontext
def shutdown_services(exception=None):
    """Завершение работы сервисов при остановке приложения"""
    try:
        global redis_manager_obj
        if redis_manager_obj:
            logger.info("Shutting down recommendation system services...")
            redis_manager_obj.close()
            logger.info("Redis connection closed")
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

# Эндпоинт для проверки работы приложения
@app.route('/')
def index():
    return {
        'service': 'Enhanced Recommendation Engine',
        'version': '2.0',
        'status': 'running',
        'endpoints': {
            'recommend_best_category': '/recommend/best-category/{user_id}',
            'enhanced_recommendations': '/recommend/enhanced/{user_id}',
            'process_batch': '/process/batch',
            'user_profile': '/profile/{user_id}',
            'health': '/health',
            'redis_health': '/health/redis',
            'api_docs': '/docs'
        }
    }

if __name__ == '__main__':
    # Настройка логирования
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(),
            logging.FileHandler('recommendation.log')
        ]
    )
    
    try:
        # Инициализация сервисов при запуске
        logger.info("Starting Enhanced Recommendation Engine...")
        
        with app.app_context():
            initialize_services()
        
        # Запуск сервера
        logger.info(f"Server starting on http://0.0.0.0:5000")
        logger.info(f"API Documentation: http://0.0.0.0:5000/docs")
        logger.info(f".NET DTO endpoint: /recommend/best-category/{{user_id}}")
        
        app.run(
            host='0.0.0.0',
            port=5000,
            debug=False,
            threaded=True
        )
    except Exception as e:
        logger.error(f"Failed to start server: {str(e)}", exc_info=True)
        raise
