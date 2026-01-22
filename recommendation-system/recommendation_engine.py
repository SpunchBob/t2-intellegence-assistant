"""
Движок рекомендаций для Recommendation System
Обрабатывает действия пользователей и генерирует рекомендации
"""

import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Set
from .models import ACTION_CATEGORY_MAPPING, Recommendation
from .redis_manager import RedisManager

logger = logging.getLogger(__name__)


class EnhancedRecommendationSystem:
    """
    Улучшенная система рекомендаций
    
    Attributes:
        user_profiles (Dict): Профили пользователей
        category_decay (Dict): Время последних действий по категориям
        redis_manager (RedisManager): Менеджер Redis
    """
    
    def __init__(self, redis_manager: RedisManager):
        """
        Инициализация системы рекомендаций
        
        Args:
            redis_manager (RedisManager): Менеджер для работы с Redis
        """
        self.user_profiles = {}
        self.category_decay = {}
        self.redis_manager = redis_manager
        logger.info("EnhancedRecommendationSystem initialized")

    def process_batch_actions(self, actions: List[Dict[str, Any]]) -> Dict[int, Dict[str, Any]]:
        """
        Пакетная обработка действий из analytics collector
        
        Args:
            actions (List[Dict]): Список действий пользователей
            
        Returns:
            Dict: Результаты обработки по пользователям
        """
        results = {}
        
        try:
            for action in actions:
                user_id = action.get('user_id')
                action_type = action.get('action_type')
                count = action.get('action_count', 1)
                
                if not all([user_id, action_type]):
                    logger.warning(f"Invalid action data: {action}")
                    continue
                
                # Инициализация данных пользователя если нужно
                if user_id not in self.user_profiles:
                    self.user_profiles[user_id] = {}
                    self.category_decay[user_id] = {}
                
                # Получаем настройки категории
                category_config = ACTION_CATEGORY_MAPPING.get(
                    action_type, 
                    ACTION_CATEGORY_MAPPING['default']
                )
                
                category = category_config['category']
                weight = category_config['weight']
                decay_rate = category_config['decay_rate']
                
                # Применяем затухание старых действий
                self._apply_decay(user_id, category, decay_rate)
                
                # Добавляем новые действия с учетом веса
                current_score = self.user_profiles[user_id].get(category, 0)
                self.user_profiles[user_id][category] = current_score + (count * weight)
                
                # Обновляем время последнего действия
                self.category_decay[user_id][category] = datetime.now()
                
                # Сохраняем в Redis для persistence
                self._save_to_redis(user_id)
                
                if user_id not in results:
                    results[user_id] = {'processed': 0, 'categories': set()}
                
                results[user_id]['processed'] += 1
                results[user_id]['categories'].add(category)
            
            logger.info(f"Processed batch of {len(actions)} actions")
            return results
            
        except Exception as e:
            logger.error(f"Batch processing failed: {str(e)}", exc_info=True)
            return {}

    def _apply_decay(self, user_id: int, category: str, decay_rate: float) -> None:
        """
        Применение затухания к старым действиям
        
        Args:
            user_id (int): Идентификатор пользователя
            category (str): Категория действий
            decay_rate (float): Коэффициент затухания
        """
        try:
            if (user_id in self.user_profiles and 
                category in self.user_profiles[user_id]):
                
                last_update = self.category_decay[user_id].get(category)
                if last_update:
                    # Вычисляем время с последнего обновления в часах
                    hours_passed = (datetime.now() - last_update).total_seconds() / 3600
                    # Применяем затухание на основе времени
                    decay_factor = decay_rate ** (hours_passed / 24)
                    self.user_profiles[user_id][category] *= decay_factor
                    logger.debug(f"Applied decay for user {user_id}, category {category}: {decay_factor}")
                    
        except Exception as e:
            logger.error(f"Failed to apply decay for user {user_id}: {str(e)}")

    def _save_to_redis(self, user_id: int) -> bool:
        """
        Сохранение профиля пользователя в Redis
        
        Args:
            user_id (int): Идентификатор пользователя
            
        Returns:
            bool: True если сохранение успешно
        """
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
        """
        Загрузка профиля пользователя из Redis
        
        Args:
            user_id (int): Идентификатор пользователя
            
        Returns:
            bool: True если загрузка успешна
        """
        try:
            profile_data = self.redis_manager.load_user_profile(user_id)
            if profile_data:
                self.user_profiles[user_id] = profile_data.get('scores', {})
                
                # Восстанавливаем временные метки
                decay_data = profile_data.get('metadata', {}).get('decay_data', {})
                for cat, time_str in decay_data.items():
                    try:
                        self.category_decay.setdefault(user_id, {})[cat] = datetime.fromisoformat(time_str)
                    except ValueError:
                        logger.warning(f"Invalid timestamp for category {cat}: {time_str}")
                
                logger.debug(f"Profile loaded from Redis for user {user_id}")
                return True
            return False
            
        except Exception as e:
            logger.error(f"Error loading from Redis for user {user_id}: {str(e)}")
            return False

    def get_enhanced_recommendations(self, user_id: int, context: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """
        Получение улучшенных рекомендаций с контекстом
        
        Args:
            user_id (int): Идентификатор пользователя
            context (Dict): Контекстные данные для фильтрации
            
        Returns:
            List[Dict]: Список рекомендаций
        """
        try:
            # Пытаемся загрузить из Redis если нет в памяти
            if user_id not in self.user_profiles:
                self._load_from_redis(user_id)
            
            # Если все еще нет данных, возвращаем рекомендации по умолчанию
            if user_id not in self.user_profiles or not self.user_profiles[user_id]:
                logger.info(f"No profile data for user {user_id}, returning fallback")
                return self._get_fallback_recommendations()
            
            scores = self.user_profiles[user_id]
            
            # Рассчитываем общий счет
            total_score = sum(scores.values())
            if total_score == 0:
                logger.warning(f"Zero total score for user {user_id}")
                return self._get_fallback_recommendations()
            
            # Создаем рекомендации
            recommendations = []
            for category, score in scores.items():
                # Рассчитываем приоритет
                priority = score / total_score
                
                # Рассчитываем уверенность на основе количества данных
                confidence = min(0.95, 0.3 + (len(scores) * 0.1))
                
                # Генерируем обоснование
                reason = self._generate_reason(category, score, priority)
                
                # Предлагаемые действия
                suggested_actions = self._get_suggested_actions(category)
                
                # Создаем объект рекомендации
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
            
            # Преобразуем в словари
            result = [rec.to_dict() for rec in recommendations[:5]]
            logger.info(f"Generated {len(result)} recommendations for user {user_id}")
            
            return result
            
        except Exception as e:
            logger.error(f"Failed to get recommendations for user {user_id}: {str(e)}", exc_info=True)
            return self._get_fallback_recommendations()

    def _generate_reason(self, category: str, score: float, priority: float) -> str:
        """
        Генерация обоснования рекомендации
        
        Args:
            category (str): Категория рекомендации
            score (float): Счет категории
            priority (float): Приоритет категории
            
        Returns:
            str: Обоснование рекомендации
        """
        reasons = {
            'chat': f"Вы активно общаетесь с ассистентом ({priority:.0%} активности)",
            'time': f"На основе вашего интереса к поиску книг ({priority:.0%} активности)",
            'messages': f"Вы часто смотрите видео-контент ({priority:.0%} активности)",
            'education': f"Ваша активность в обучении высока ({priority:.0%} активности)",
            'software': f"Вы активно используете функционал системы ({priority:.0%} активности)",
            'general': f"Общая активность в категории {category} ({priority:.0%})"
        }
        return reasons.get(category, f"На основе вашей активности в категории {category} ({priority:.0%})")

    def _get_suggested_actions(self, category: str) -> List[str]:
        """
        Получение предлагаемых действий для категории
        
        Args:
            category (str): Категория рекомендации
            
        Returns:
            List[str]: Список предлагаемых действий
        """
        suggestions = {
            'chat': ["Задать новый вопрос", "Продолжить диалог", "Изменить тему"],
            'time': ["Поискать новые книги", "Посмотреть бестселлеры", "Выбрать по жанру"],
            'messages': ["Посмотреть рекомендации", "Подборка по интересам", "Популярное сейчас"],
            'education': ["Новые курсы", "Статьи по теме", "Вебинары"],
            'software': ["Изучить новые функции", "Настройки профиля", "Советы по использованию"],
            'general': ["Исследовать категорию", "Посмотреть новинки", "Специальные предложения"]
        }
        return suggestions.get(category, ["Исследовать категорию"])

    def _get_fallback_recommendations(self) -> List[Dict[str, Any]]:
        """
        Рекомендации по умолчанию
        
        Returns:
            List[Dict]: Список рекомендаций по умолчанию
        """
        logger.info("Returning fallback recommendations")
        return [
            {
                'category': 'chat',
                'priority': 0.3,
                'confidence': 0.5,
                'reason': 'Популярная категория среди пользователей',
                'suggested_actions': ['Начать диалог', 'Задать вопрос']
            },
            {
                'category': 'education',
                'priority': 0.25,
                'confidence': 0.5,
                'reason': 'Часто просматриваемая категория',
                'suggested_actions': ['Новые курсы', 'Образовательные материалы']
            }
        ]

    def _apply_context_filters(self, recommendations: List[Recommendation], 
                              context: Dict[str, Any]) -> List[Recommendation]:
        """
        Применение контекстных фильтров
        
        Args:
            recommendations (List[Recommendation]): Список рекомендаций
            context (Dict): Контекстные данные
            
        Returns:
            List[Recommendation]: Отфильтрованные рекомендации
        """
        filtered = []
        
        try:
            current_hour = datetime.now().hour
            
            for rec in recommendations:
                # Пример фильтрации по времени суток
                if 'time_of_day' in context or current_hour:
                    time_of_day = context.get('time_of_day')
                    if not time_of_day:
                        if 6 <= current_hour < 12:
                            time_of_day = 'morning'
                        elif 12 <= current_hour < 18:
                            time_of_day = 'afternoon'
                        else:
                            time_of_day = 'evening'
                    
                    if time_of_day == 'morning' and rec.category == 'education':
                        rec.priority *= 1.2
                        logger.debug("Boosted education recommendations for morning")
                    elif time_of_day == 'evening' and rec.category == 'chat':
                        rec.priority *= 1.3
                        logger.debug("Boosted chat recommendations for evening")
                
                # Другие контекстные фильтры
                if 'user_preferences' in context:
                    user_prefs = context['user_preferences']
                    if rec.category in user_prefs.get('preferred_categories', []):
                        rec.priority *= 1.5
                
                filtered.append(rec)
            
            filtered.sort(key=lambda x: x.priority, reverse=True)
            return filtered
            
        except Exception as e:
            logger.error(f"Failed to apply context filters: {str(e)}")
            return recommendations

    def clear_user_profile(self, user_id: int) -> bool:
        """
        Очистка профиля пользователя
        
        Args:
            user_id (int): Идентификатор пользователя
            
        Returns:
            bool: True если очистка успешна
        """
        try:
            if user_id in self.user_profiles:
                del self.user_profiles[user_id]
            
            if user_id in self.category_decay:
                del self.category_decay[user_id]
            
            # Удаляем из Redis
            success = self.redis_manager.delete_user_profile(user_id)
            
            logger.info(f"Profile cleared for user {user_id}")
            return success
            
        except Exception as e:
            logger.error(f"Failed to clear profile for user {user_id}: {str(e)}")
            return False

    def get_user_profile(self, user_id: int) -> Optional[Dict[str, Any]]:
        """
        Получение профиля пользователя
        
        Args:
            user_id (int): Идентификатор пользователя
            
        Returns:
            Optional[Dict]: Профиль пользователя или None
        """
        try:
            if user_id in self.user_profiles:
                return {
                    'user_id': user_id,
                    'scores': self.user_profiles[user_id],
                    'last_updated': self.category_decay.get(user_id, {}),
                    'categories_count': len(self.user_profiles[user_id])
                }
            return None
            
        except Exception as e:
            logger.error(f"Failed to get profile for user {user_id}: {str(e)}")
            return None

    def get_all_user_ids(self) -> List[int]:
        """
        Получение списка всех пользователей в системе
        
        Returns:
            List[int]: Список идентификаторов пользователей
        """
        try:
            return list(self.user_profiles.keys())
        except Exception as e:
            logger.error(f"Failed to get user ids: {str(e)}")
            return []

    def get_system_stats(self) -> Dict[str, Any]:
        """
        Получение статистики системы
        
        Returns:
            Dict: Статистика системы рекомендаций
        """
        try:
            total_users = len(self.user_profiles)
            total_categories = sum(len(scores) for scores in self.user_profiles.values())
            
            return {
                'total_users': total_users,
                'total_categories': total_categories,
                'avg_categories_per_user': total_categories / total_users if total_users > 0 else 0,
                'timestamp': datetime.now().isoformat(),
                'redis_available': self.redis_manager is not None
            }
            
        except Exception as e:
            logger.error(f"Failed to get system stats: {str(e)}")
            return {
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }