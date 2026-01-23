import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Set

logger = logging.getLogger(__name__)

# Класс Recommendation (дублируем или импортируем)
class Recommendation:
    def __init__(self, category: str, priority: float, confidence: float, 
                 reason: str, suggested_actions: List[str]):
        self.category = category
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
        logger.info("EnhancedRecommendationSystem initialized")

    def process_batch_actions(self, actions: List[Dict[str, Any]]) -> Dict[int, Dict[str, Any]]:
        results = {}
        
        try:
            for action in actions:
                user_id = action.get('user_id')
                action_type = action.get('action_type')
                count = action.get('action_count', 1)
                
                if not all([user_id, action_type]):
                    logger.warning(f"Invalid action data: {action}")
                    continue
                
                if user_id not in self.user_profiles:
                    self.user_profiles[user_id] = {}
                    self.category_decay[user_id] = {}
                
                # Используем маппинг из routes.py
                category_config = self._get_category_config(action_type)
                
                category = category_config['category']
                weight = category_config['weight']
                decay_rate = category_config['decay_rate']
                
                self._apply_decay(user_id, category, decay_rate)
                
                current_score = self.user_profiles[user_id].get(category, 0)
                self.user_profiles[user_id][category] = current_score + (count * weight)
                
                self.category_decay[user_id][category] = datetime.now()
                
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

    def _get_category_config(self, action_type: str) -> Dict[str, Any]:
        """Получение конфигурации категории для действия"""
        category_mapping = {
            'chatting_assistant': {'category': 'chat', 'weight': 1.2, 'decay_rate': 0.95},
            'search_books': {'category': 'time', 'weight': 0.9, 'decay_rate': 0.9},
            'watch_videos': {'category': 'messages', 'weight': 1.1, 'decay_rate': 0.85},
            'read_articles': {'category': 'education', 'weight': 0.7, 'decay_rate': 0.8},
            'use_function_x': {'category': 'software', 'weight': 1.0, 'decay_rate': 0.9},
        }
        
        return category_mapping.get(action_type, 
            {'category': 'general', 'weight': 0.5, 'decay_rate': 0.7})

    def _apply_decay(self, user_id: int, category: str, decay_rate: float) -> None:
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
        try:
            profile_data = self.redis_manager.load_user_profile(user_id)
            if profile_data:
                self.user_profiles[user_id] = profile_data.get('scores', {})
                
                decay_data = profile_data.get('metadata', {}).get('decay_data', {})
                for cat, time_str in decay_data.items():
                    try:
                        self.category_decay.setdefault(user_id, {})[cat] = datetime.fromisoformat(time_str)
                    except ValueError:
                        pass
                
                logger.debug(f"Profile loaded from Redis for user {user_id}")
                return True
            return False
            
        except Exception as e:
            logger.error(f"Error loading from Redis for user {user_id}: {str(e)}")
            return False

    def get_enhanced_recommendations(self, user_id: int, context: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        try:
            if user_id not in self.user_profiles:
                self._load_from_redis(user_id)
            
            if user_id not in self.user_profiles or not self.user_profiles[user_id]:
                logger.info(f"No profile data for user {user_id}, returning fallback")
                return self._get_fallback_recommendations()
            
            scores = self.user_profiles[user_id]
            
            total_score = sum(scores.values())
            if total_score == 0:
                logger.warning(f"Zero total score for user {user_id}")
                return self._get_fallback_recommendations()
            
            recommendations = []
            for category, score in scores.items():
                priority = score / total_score
                
                confidence = min(0.95, 0.3 + (len(scores) * 0.1))
                
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
            
            if context:
                recommendations = self._apply_context_filters(recommendations, context)
            
            recommendations.sort(key=lambda x: (x.priority, x.confidence), reverse=True)
            
            result = [rec.to_dict() for rec in recommendations[:5]]
            logger.info(f"Generated {len(result)} recommendations for user {user_id}")
            
            return result
            
        except Exception as e:
            logger.error(f"Failed to get recommendations for user {user_id}: {str(e)}", exc_info=True)
            return self._get_fallback_recommendations()

    def _generate_reason(self, category: str, score: float, priority: float) -> str:
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
        filtered = []
        
        try:
            current_hour = datetime.now().hour
            
            for rec in recommendations:
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
