import json
import logging
import random
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Set

logger = logging.getLogger(__name__)

# Импортируем категории из models
try:
    from models import CATEGORIES
except ImportError:
    CATEGORIES = {"gb": "Gigabytes", "min": "Minutes", "msg": "Messages"}

# Класс Recommendation
class Recommendation:
    def __init__(self, category: str, priority: float, confidence: float, 
                 reason: str, suggested_actions: List[str]):
        # Проверяем, что категория валидна
        category_lower = category.lower()
        if category_lower not in CATEGORIES:
            raise ValueError(f"Invalid category: {category}. Must be one of {list(CATEGORIES.keys())}")
        
        self.category = category_lower
        self.priority = priority
        self.confidence = confidence
        self.reason = reason
        self.suggested_actions = suggested_actions
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'category': self.category,
            'priority': round(self.priority, 4),
            'confidence': round(self.confidence, 2),
            'reason': self.reason,
            'suggested_actions': self.suggested_actions
        }


class EnhancedRecommendationSystem:
    def __init__(self, redis_manager):
        self.user_profiles = {}
        self.category_decay = {}
        self.redis_manager = redis_manager
        self.available_categories = list(CATEGORIES.keys())
        logger.info(f"EnhancedRecommendationSystem initialized with categories: {self.available_categories}")

    def process_batch_actions(self, actions: List[Dict[str, Any]]) -> Dict[int, Dict[str, Any]]:
        """
        Обработка пакета действий пользователей
        Категории определяются по action_type:
        - 'gb_purchase', 'gb_usage' → 'gb'
        - 'min_usage', 'min_purchase' → 'min'
        - 'msg_send', 'msg_receive' → 'msg'
        """
        results = {}
        
        try:
            for action in actions:
                user_id = action.get('user_id')
                action_type = action.get('action_type', '').lower()
                count = action.get('action_count', 1)
                
                if not all([user_id, action_type]):
                    logger.warning(f"Invalid action data: {action}")
                    continue
                
                if user_id not in self.user_profiles:
                    self._initialize_user_profile(user_id)
                
                # Определяем категорию по типу действия
                category_config = self._get_category_config(action_type)
                
                category = category_config['category']
                weight = category_config['weight']
                decay_rate = category_config['decay_rate']
                
                # Применяем затухание (decay) для данной категории
                self._apply_decay(user_id, category, decay_rate)
                
                # Обновляем счетчик категории
                current_score = self.user_profiles[user_id].get(category, 0)
                self.user_profiles[user_id][category] = current_score + (count * weight)
                
                # Обновляем время последнего действия для категории
                self.category_decay[user_id][category] = datetime.now()
                
                # Сохраняем в Redis
                self._save_to_redis(user_id)
                
                # Обновляем результаты обработки
                if user_id not in results:
                    results[user_id] = {'processed': 0, 'categories': set()}
                
                results[user_id]['processed'] += 1
                results[user_id]['categories'].add(category)
            
            logger.info(f"Processed batch of {len(actions)} actions")
            return results
            
        except Exception as e:
            logger.error(f"Batch processing failed: {str(e)}", exc_info=True)
            return {}

    def _initialize_user_profile(self, user_id: int) -> None:
        """Инициализация профиля пользователя с нулевыми значениями для всех категорий"""
        self.user_profiles[user_id] = {category: 0.0 for category in self.available_categories}
        self.category_decay[user_id] = {category: datetime.now() for category in self.available_categories}
        logger.debug(f"Initialized profile for user {user_id}")

    def _get_category_config(self, action_type: str) -> Dict[str, Any]:
        """
        Определение категории и параметров на основе типа действия
        """
        # Маппинг типов действий на категории
        category_mapping = {
            # GB actions
            'gb_purchase': 'gb',
            'gb_usage': 'gb',
            'gigabyte_purchase': 'gb',
            'gigabyte_usage': 'gb',
            'storage_purchase': 'gb',
            'storage_usage': 'gb',
            
            # MIN actions
            'min_usage': 'min',
            'min_purchase': 'min',
            'minute_usage': 'min',
            'minute_purchase': 'min',
            'time_purchase': 'min',
            'time_usage': 'min',
            'premium_time': 'min',
            
            # MSG actions
            'msg_send': 'msg',
            'msg_receive': 'msg',
            'message_send': 'msg',
            'message_receive': 'msg',
            'chat_message': 'msg',
            'special_message': 'msg',
            'notification': 'msg',
            
            # Общие действия
            'login': 'general',
            'logout': 'general',
            'profile_view': 'general',
            'settings_change': 'general'
        }
        
        # Определяем категорию
        category_key = action_type.lower()
        category = category_mapping.get(category_key, 'general')
        
        # Если категория 'general', рандомно назначаем одну из трех основных
        if category == 'general':
            # Для общих действий распределяем между категориями случайно
            category = random.choice(self.available_categories)
        
        # Параметры для каждой категории
        configs = {
            'gb': {'category': 'gb', 'weight': 1.0, 'decay_rate': 0.95},
            'min': {'category': 'min', 'weight': 0.9, 'decay_rate': 0.9},
            'msg': {'category': 'msg', 'weight': 1.1, 'decay_rate': 0.85}
        }
        
        return configs.get(category, {'category': 'gb', 'weight': 0.5, 'decay_rate': 0.7})

    def _apply_decay(self, user_id: int, category: str, decay_rate: float) -> None:
        """Применение затухания к счетчику категории"""
        try:
            if (user_id in self.user_profiles and 
                category in self.user_profiles[user_id]):
                
                last_update = self.category_decay[user_id].get(category)
                if last_update:
                    hours_passed = (datetime.now() - last_update).total_seconds() / 3600
                    decay_factor = decay_rate ** (hours_passed / 24)
                    self.user_profiles[user_id][category] *= decay_factor
                    logger.debug(f"Applied decay for user {user_id}, category {category}: {decay_factor}")
                    
        except Exception as e:
            logger.error(f"Failed to apply decay for user {user_id}: {str(e)}")

    def _save_to_redis(self, user_id: int) -> bool:
        """Сохранение профиля пользователя в Redis"""
        try:
            profile_data = {
                'scores': self.user_profiles.get(user_id, {}),
                'last_updated': datetime.now().isoformat(),
                'metadata': {
                    'categories_count': len(self.user_profiles.get(user_id, {})),
                    'decay_data': {
                        cat: str(time) for cat, time in self.category_decay.get(user_id, {}).items()
                    }
                }
            }
            
            success = self.redis_manager.save_user_profile(user_id, profile_data)
            if success:
                logger.debug(f"Profile saved to Redis for user {user_id}")
            else:
                logger.warning(f"Failed to save profile to Redis for user {user_id}")
                
            return success
            
        except Exception as e:
            logger.error(f"Error saving to Redis for user {user_id}: {str(e)}")
            return False

    def _load_from_redis(self, user_id: int) -> bool:
        """Загрузка профиля пользователя из Redis"""
        try:
            profile_data = self.redis_manager.load_user_profile(user_id)
            if profile_data:
                self.user_profiles[user_id] = profile_data.get('scores', {})
                
                # Инициализируем недостающие категории
                for category in self.available_categories:
                    if category not in self.user_profiles[user_id]:
                        self.user_profiles[user_id][category] = 0.0
                
                decay_data = profile_data.get('metadata', {}).get('decay_data', {})
                self.category_decay[user_id] = {}
                for cat in self.available_categories:
                    if cat in decay_data:
                        try:
                            self.category_decay[user_id][cat] = datetime.fromisoformat(decay_data[cat])
                        except ValueError:
                            self.category_decay[user_id][cat] = datetime.now()
                    else:
                        self.category_decay[user_id][cat] = datetime.now()
                
                logger.debug(f"Profile loaded from Redis for user {user_id}")
                return True
            return False
            
        except Exception as e:
            logger.error(f"Error loading from Redis for user {user_id}: {str(e)}")
            return False

    def get_enhanced_recommendations(self, user_id: int, context: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """Получение рекомендаций для пользователя"""
        try:
            # Загружаем профиль если его нет в памяти
            if user_id not in self.user_profiles:
                loaded = self._load_from_redis(user_id)
                if not loaded:
                    # Создаем новый профиль
                    self._initialize_user_profile(user_id)
                    logger.info(f"Created new profile for user {user_id}")
            
            scores = self.user_profiles[user_id]
            
            # Проверяем есть ли активность
            total_score = sum(scores.values())
            if total_score == 0:
                logger.info(f"No activity for user {user_id}, returning balanced recommendations")
                return self._get_balanced_recommendations()
            
            # Создаем рекомендации для каждой категории
            recommendations = []
            for category in self.available_categories:
                score = scores.get(category, 0)
                priority = score / total_score if total_score > 0 else 0.33
                
                # Базовая уверность зависит от количества действий
                confidence = min(0.95, 0.3 + (priority * 0.5))
                
                reason = self._generate_reason(category, score, priority)
                suggested_actions = self._get_suggested_actions(category)
                
                recommendation = Recommendation(
                    category=category,
                    priority=priority,
                    confidence=confidence,
                    reason=reason,
                    suggested_actions=suggested_actions
                )
                
                recommendations.append(recommendation)
            
            # Применяем контекстные фильтры если есть
            if context:
                recommendations = self._apply_context_filters(recommendations, context)
            
            # Сортируем по приоритету и уверенности
            recommendations.sort(key=lambda x: (x.priority, x.confidence), reverse=True)
            
            # Конвертируем в словари
            result = [rec.to_dict() for rec in recommendations]
            logger.info(f"Generated {len(result)} recommendations for user {user_id}")
            
            return result
            
        except Exception as e:
            logger.error(f"Failed to get recommendations for user {user_id}: {str(e)}", exc_info=True)
            return self._get_fallback_recommendations()

    def _generate_reason(self, category: str, score: float, priority: float) -> str:
        """Генерация обоснования для рекомендации"""
        reasons = {
            'gb': f"На основе вашего использования гигабайт ({score:.1f} ед., {priority:.0%} активности)",
            'min': f"Учитывая ваше использование минут ({score:.1f} ед., {priority:.0%} активности)",
            'msg': f"На основе вашей активности с сообщениями ({score:.1f} ед., {priority:.0%} активности)"
        }
        return reasons.get(category, f"Общая активность в категории {category} ({priority:.0%})")

    def _get_suggested_actions(self, category: str) -> List[str]:
        """Получение предлагаемых действий для категории"""
        suggestions = {
            'gb': [
                "Купить дополнительные гигабайты",
                "Проверить остаток трафика",
                "Использовать ГБ для премиум-контента"
            ],
            'min': [
                "Приобрести премиум-минуты",
                "Использовать минуты для специальных функций",
                "Проверить баланс минут"
            ],
            'msg': [
                "Отправить специальное сообщение",
                "Проверить входящие сообщения",
                "Использовать премиум-сообщения"
            ]
        }
        return suggestions.get(category, ["Исследовать категорию"])

    def _get_balanced_recommendations(self) -> List[Dict[str, Any]]:
        """Сбалансированные рекомендации для новых пользователей"""
        logger.info("Returning balanced recommendations for new user")
        return [
            {
                'category': 'gb',
                'priority': 0.33,
                'confidence': 0.5,
                'reason': 'Популярная категория среди новых пользователей',
                'suggested_actions': ['Купить стартовый пакет ГБ', 'Проверить доступные предложения']
            },
            {
                'category': 'min',
                'priority': 0.33,
                'confidence': 0.5,
                'reason': 'Основной функционал платформы',
                'suggested_actions': ['Приобрести базовые минуты', 'Изучить возможности']
            },
            {
                'category': 'msg',
                'priority': 0.34,
                'confidence': 0.5,
                'reason': 'Важно для коммуникации',
                'suggested_actions': ['Отправить тестовое сообщение', 'Настроить уведомления']
            }
        ]

    def _get_fallback_recommendations(self) -> List[Dict[str, Any]]:
        """Резервные рекомендации при ошибке"""
        logger.warning("Returning fallback recommendations")
        return [
            {
                'category': 'gb',
                'priority': 0.4,
                'confidence': 0.3,
                'reason': 'Базовая рекомендация',
                'suggested_actions': ['Исследовать категорию ГБ']
            },
            {
                'category': 'min',
                'priority': 0.3,
                'confidence': 0.3,
                'reason': 'Базовая рекомендация',
                'suggested_actions': ['Исследовать категорию минут']
            },
            {
                'category': 'msg',
                'priority': 0.3,
                'confidence': 0.3,
                'reason': 'Базовая рекомендация',
                'suggested_actions': ['Исследовать категорию сообщений']
            }
        ]

    def _apply_context_filters(self, recommendations: List[Recommendation], 
                              context: Dict[str, Any]) -> List[Recommendation]:
        """Применение контекстных фильтров к рекомендациям"""
        filtered = recommendations.copy()
        
        try:
            # Бонусы в зависимости от времени суток
            current_hour = datetime.now().hour
            
            for rec in filtered:
                # Утренние часы (6-12) - бонус для GB
                if 6 <= current_hour < 12 and rec.category == 'gb':
                    rec.priority *= 1.2
                    rec.reason += " (утренняя акция!)"
                    logger.debug("Boosted GB recommendations for morning")
                
                # Вечерние часы (18-24) - бонус для MSG
                elif 18 <= current_hour < 24 and rec.category == 'msg':
                    rec.priority *= 1.3
                    rec.reason += " (вечерняя активность!)"
                    logger.debug("Boosted MSG recommendations for evening")
                
                # Дневные часы (12-18) - бонус для MIN
                elif 12 <= current_hour < 18 and rec.category == 'min':
                    rec.priority *= 1.1
                    logger.debug("Boosted MIN recommendations for afternoon")
            
            # Сортируем по обновленному приоритету
            filtered.sort(key=lambda x: x.priority, reverse=True)
            return filtered
            
        except Exception as e:
            logger.error(f"Failed to apply context filters: {str(e)}")
            return recommendations

    def clear_user_profile(self, user_id: int) -> bool:
        """Очистка профиля пользователя"""
        try:
            if user_id in self.user_profiles:
                del self.user_profiles[user_id]
            
            if user_id in self.category_decay:
                del self.category_decay[user_id]
            
            success = self.redis_manager.delete_user_profile(user_id)
            
            logger.info(f"Profile cleared for user {user_id}")
            return success
            
        except Exception as e:
            logger.error(f"Failed to clear profile for user {user_id}: {str(e)}")
            return False
    
    def get_user_profile_summary(self, user_id: int) -> Dict[str, Any]:
        """Получение сводки по профилю пользователя"""
        try:
            if user_id not in self.user_profiles:
                self._load_from_redis(user_id)
            
            if user_id in self.user_profiles:
                scores = self.user_profiles[user_id]
                total = sum(scores.values())
                
                return {
                    'user_id': user_id,
                    'categories': {
                        cat: {
                            'score': scores.get(cat, 0),
                            'percentage': (scores.get(cat, 0) / total * 100) if total > 0 else 0,
                            'last_update': self.category_decay.get(user_id, {}).get(cat, None)
                        }
                        for cat in self.available_categories
                    },
                    'total_score': total,
                    'last_updated': datetime.now().isoformat()
                }
            
            return {'user_id': user_id, 'error': 'Profile not found'}
            
        except Exception as e:
            logger.error(f"Failed to get profile summary: {str(e)}")
            return {'user_id': user_id, 'error': str(e)}
