import json
import logging
from typing import Dict, List, Any
from datetime import datetime
from flask_restx import Resource, reqparse, fields
from flask import request, current_app

logger = logging.getLogger(__name__)

# Создаем парсер для запросов
batch_parser = reqparse.RequestParser()
batch_parser.add_argument('actions', type=list, location='json', required=True)

context_parser = reqparse.RequestParser()
context_parser.add_argument('context', type=str, location='args')

# Создаем модели полей для Swagger
action_fields = {
    'user_id': fields.Integer(required=True, description='Идентификатор пользователя'),
    'action_type': fields.String(required=True, description='Тип действия'),
    'action_count': fields.Integer(required=True, description='Количество действий'),
    'timestamp': fields.String(description='Временная метка')
}

recommendation_fields = {
    'category': fields.String(description='Категория'),
    'priority': fields.Float(description='Приоритет 0-1'),
    'confidence': fields.Float(description='Уверенность в рекомендации'),
    'reason': fields.String(description='Обоснование рекомендации'),
    'suggested_actions': fields.List(fields.String, description='Предлагаемые действия')
}


class ProcessBatchResource(Resource):
    def post(self):
        """
        Пакетная обработка действий от analytics collector
        """
        try:
            data = batch_parser.parse_args()
            actions = data['actions']
            
            if not isinstance(actions, list):
                error_msg = 'Expected a list of actions'
                logger.error(error_msg)
                return {'error': error_msg}, 400
            
            # Используем контекст приложения
            with current_app.app_context():
                rec_system = current_app.config.get('RECOMMENDATION_SYSTEM')
                if not rec_system:
                    error_msg = 'Recommendation system not initialized'
                    logger.error(error_msg)
                    return {'error': error_msg}, 500
                
                results = rec_system.process_batch_actions(actions)
            
            # Форматируем ответ
            response = {}
            for user_id, stats in results.items():
                response[user_id] = {
                    'actions_processed': stats['processed'],
                    'categories_affected': list(stats['categories']),
                    'timestamp': datetime.now().isoformat()
                }
            
            logger.info(f"Processed batch of {len(actions)} actions")
            return response
            
        except Exception as e:
            logger.error(f"Batch processing failed: {str(e)}", exc_info=True)
            return {'error': 'Internal server error'}, 500


class EnhancedRecommendationsResource(Resource):
    def get(self, user_id):
        """
        Получение рекомендаций с контекстом
        """
        try:
            args = context_parser.parse_args()
            context_str = args.get('context')
            
            # Парсим контекст если он есть
            context = {}
            if context_str:
                try:
                    context = json.loads(context_str)
                    if not isinstance(context, dict):
                        error_msg = 'Context must be a JSON object'
                        logger.error(error_msg)
                        return {'error': error_msg}, 400
                except json.JSONDecodeError as e:
                    error_msg = f'Invalid context JSON: {str(e)}'
                    logger.error(error_msg)
                    return {'error': error_msg}, 400
            
            # Используем контекст приложения
            with current_app.app_context():
                rec_system = current_app.config.get('RECOMMENDATION_SYSTEM')
                if not rec_system:
                    error_msg = 'Recommendation system not initialized'
                    logger.error(error_msg)
                    return {'error': error_msg}, 500
                
                recommendations = rec_system.get_enhanced_recommendations(user_id, context)
            
            response = {
                'user_id': user_id,
                'timestamp': datetime.now().isoformat(),
                'context_used': bool(context),
                'recommendations': recommendations
            }
            
            logger.info(f"Generated recommendations for user {user_id}")
            return response
            
        except Exception as e:
            logger.error(f"Failed to get recommendations for user {user_id}: {str(e)}", exc_info=True)
            return {'error': 'Internal server error'}, 500


class UserProfileResource(Resource):
    def get(self, user_id):
        """
        Получение профиля пользователя
        """
        try:
            with current_app.app_context():
                rec_system = current_app.config.get('RECOMMENDATION_SYSTEM')
                if not rec_system:
                    return {'message': 'Recommendation system not initialized'}, 500
                
                if user_id in rec_system.user_profiles:
                    return {
                        'user_id': user_id,
                        'profile': rec_system.user_profiles[user_id],
                        'last_updated': datetime.now().isoformat()
                    }
            
            return {'message': 'Profile not found'}, 404
            
        except Exception as e:
            logger.error(f"Failed to get profile for user {user_id}: {str(e)}", exc_info=True)
            return {'error': 'Internal server error'}, 500
    
    def delete(self, user_id):
        """
        Удаление профиля пользователя
        """
        try:
            with current_app.app_context():
                rec_system = current_app.config.get('RECOMMENDATION_SYSTEM')
                if not rec_system:
                    return {'message': 'Recommendation system not initialized'}, 500
                
                success = rec_system.clear_user_profile(user_id)
            
            if success:
                return {'message': f'Profile for user {user_id} cleared successfully'}
            else:
                return {'message': f'Failed to clear profile for user {user_id}'}, 500
                
        except Exception as e:
            logger.error(f"Failed to delete profile for user {user_id}: {str(e)}", exc_info=True)
            return {'error': 'Internal server error'}, 500


class RedisHealthResource(Resource):
    def get(self):
        """
        Проверка подключения к Redis
        """
        try:
            with current_app.app_context():
                redis_manager = current_app.config.get('REDIS_MANAGER')
                if not redis_manager:
                    return {'redis': 'not_initialized'}, 500
                
                health_status = redis_manager.health_check()
            
            if health_status['status'] == 'connected':
                return {'redis': 'connected'}
            elif health_status['status'] == 'disconnected':
                return {'redis': 'disconnected'}, 500
            else:
                return {'redis': 'error', 'details': health_status.get('error')}, 500
                
        except Exception as e:
            logger.error(f"Redis health check failed: {str(e)}")
            return {'redis': 'error', 'error': str(e)}, 500


class SystemHealthResource(Resource):
    def get(self):
        """
        Проверка общего здоровья системы
        """
        try:
            with current_app.app_context():
                redis_manager = current_app.config.get('REDIS_MANAGER')
                rec_system = current_app.config.get('RECOMMENDATION_SYSTEM')
                
                status = {
                    'status': 'healthy',
                    'timestamp': datetime.now().isoformat(),
                    'redis': 'unknown',
                    'recommendation_system': 'initialized' if rec_system else 'not_initialized',
                    'users_in_memory': len(rec_system.user_profiles) if rec_system else 0
                }
                
                if redis_manager:
                    redis_health = redis_manager.health_check()
                    status['redis'] = redis_health['status']
            
            logger.debug("System health check completed")
            return status
            
        except Exception as e:
            logger.error(f"System health check failed: {str(e)}", exc_info=True)
            return {
                'status': 'unhealthy',
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }, 500
