"""
Модели данных для Recommendation System
"""

from typing import List, Dict, Any
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

# Класс Recommendation
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
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Recommendation':
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
