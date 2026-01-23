"""
Модели данных для Recommendation System
"""

from typing import List, Dict, Any, Optional
from datetime import datetime
import logging
from dataclasses import dataclass, asdict
import json

logger = logging.getLogger(__name__)

# Константные категории
CATEGORIES = {
    "gb": "Gigabytes",
    "min": "Minutes", 
    "msg": "Messages"
}

# Класс Recommendation
class Recommendation:
    def __init__(self, category: str, priority: float = 0.5, confidence: float = 0.5, 
                 reason: str = "", suggested_actions: List[str] = None):
        # Проверяем, что категория существует (в нижнем регистре)
        category_lower = category.lower()
        if category_lower not in CATEGORIES:
            raise ValueError(f"Invalid category: {category}. Must be one of {list(CATEGORIES.keys())}")
        
        self.category = category_lower  # Сохраняем в нижнем регистре для консистентности
        self.priority = priority
        self.confidence = confidence
        self.reason = reason
        self.suggested_actions = suggested_actions or []
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'category': self.category,
            'priority': self.priority,
            'confidence': self.confidence,
            'reason': self.reason,
            'suggested_actions': self.suggested_actions
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Recommendation':
        try:
            return cls(
                category=data['category'],
                priority=data.get('priority', 0.5),
                confidence=data.get('confidence', 0.5),
                reason=data.get('reason', ''),
                suggested_actions=data.get('suggested_actions', [])
            )
        except (KeyError, ValueError) as e:
            logger.error(f"Failed to create Recommendation from dict: {str(e)}")
            raise ValueError(f"Invalid recommendation data: {str(e)}")


# DTO для соответствия .NET формату
@dataclass
class BestCategoryDTO:
    """DTO для передачи лучшей категории в .NET приложение"""
    Id: int
    BestCategorytName: str = ""  # Обратите внимание на опечатку 't' - должно совпадать с C# DTO
    
    def to_json(self) -> str:
        """Конвертирует в JSON строку"""
        return json.dumps(asdict(self), ensure_ascii=False)
    
    def to_dict(self) -> Dict[str, Any]:
        """Конвертирует в словарь Python"""
        return asdict(self)
    
    @classmethod
    def from_user_data(cls, user_id: int, best_category: str) -> 'BestCategoryDTO':
        """Создает DTO из данных пользователя"""
        # Приводим категорию к нижнему регистру для консистентности
        return cls(Id=user_id, BestCategorytName=best_category.lower())
