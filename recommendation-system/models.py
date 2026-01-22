"""
Модели данных для Recommendation System
Определяет структуры данных и Swagger модели
"""

from typing import List, Dict, Any
from datetime import datetime
import logging
from flask_restx import fields

logger = logging.getLogger(__name__)

# Swagger модели для документации API
action_model = {
    'user_id': fields.Integer(required=True, description='Идентификатор пользователя'),
    'action_type': fields.String(required=True, description='Тип действия'),
    'action_count': fields.Integer(required=True, description='Количество действий'),
    'timestamp': fields.String(description='Временная метка')
}

recommendation_model = {
    'category': fields.String(description='Категория рекомендации'),
    'priority': fields.Float(description='Приоритет 0-1'),
    'confidence': fields.Float(description='Уверенность в рекомендации 0-1'),
    'reason': fields.String(description='Обоснование рекомендации'),
    'suggested_actions': fields.List(fields.String, description='Предлагаемые действия')
}

# Маппинг действий на категории с весами и коэффициентами затухания
ACTION_CATEGORY_MAPPING = {
    'chatting_assistant': {
        'category': 'chat',
        'weight': 1.2,
        'decay_rate': 0.95  # Коэффициент затухания со временем
    },
    'search_books': {
        'category': 'time',
        'weight': 0.9,
        'decay_rate': 0.9
    },
    'watch_videos': {
        'category': 'messages',
        'weight': 1.1,
        'decay_rate': 0.85
    },
    'read_articles': {
        'category': 'education',
        'weight': 0.7,
        'decay_rate': 0.8
    },
    'use_function_x': {
        'category': 'software',
        'weight': 1.0,
        'decay_rate': 0.9
    },
    'default': {
        'category': 'general',
        'weight': 0.5,
        'decay_rate': 0.7
    }
}


class Recommendation:
    """
    Модель рекомендации
    
    Attributes:
        category (str): Категория рекомендации
        priority (float): Приоритет (0-1)
        confidence (float): Уверенность в рекомендации (0-1)
        reason (str): Обоснование рекомендации
        suggested_actions (List[str]): Предлагаемые действия
    """
    
    def __init__(self, category: str, priority: float, confidence: float, 
                 reason: str, suggested_actions: List[str]):
        self.category = category
        self.priority = priority
        self.confidence = confidence
        self.reason = reason
        self.suggested_actions = suggested_actions
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Преобразование в словарь
        
        Returns:
            Dict[str, Any]: Словарь с данными рекомендации
        """
        return {
            'category': self.category,
            'priority': round(self.priority, 4),
            'confidence': round(self.confidence, 2),
            'reason': self.reason,
            'suggested_actions': self.suggested_actions
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Recommendation':
        """
        Создание из словаря
        
        Args:
            data (Dict[str, Any]): Словарь с данными
            
        Returns:
            Recommendation: Объект рекомендации
        """
        try:
            return cls(
                category=data['category'],
                priority=float(data['priority']),
                confidence=float(data['confidence']),
                reason=data['reason'],
                suggested_actions=data['suggested_actions']
            )
        except (KeyError, ValueError) as e:
            logger.error(f"Failed to create Recommendation from dict: {str(e)}")
            raise ValueError(f"Invalid recommendation data: {str(e)}")