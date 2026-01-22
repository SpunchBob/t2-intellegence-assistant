"""
Модели данных для Analytics Collector
Определяет структуры данных и методы валидации
"""

import json
from dataclasses import dataclass, asdict
from typing import Dict, Any
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


@dataclass
class UserAction:
    """
    Модель действия пользователя
    
    Attributes:
        user_id (str): Идентификатор пользователя
        action (str): Тип выполненного действия
    """
    
    user_id: str
    action: str
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Преобразование объекта в словарь
        
        Returns:
            Dict[str, Any]: Словарь с данными действия
        """
        return asdict(self)
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'UserAction':
        """
        Создание объекта UserAction из словаря
        
        Args:
            data (Dict[str, Any]): Словарь с данными
            
        Returns:
            UserAction: Объект действия пользователя
            
        Raises:
            ValueError: Если данные невалидны или отсутствуют обязательные поля
        """
        if not isinstance(data, dict):
            error_msg = "Data must be a dictionary"
            logger.error(error_msg)
            raise ValueError(error_msg)
        
        user_id = data.get("user_id")
        action = data.get("action")
        
        if not user_id:
            error_msg = "user_id is required"
            logger.error(error_msg)
            raise ValueError(error_msg)
        if not action:
            error_msg = "action is required"
            logger.error(error_msg)
            raise ValueError(error_msg)
        
        try:
            return cls(
                user_id=str(user_id),
                action=str(action)
            )
        except Exception as e:
            error_msg = f"Failed to create UserAction: {str(e)}"
            logger.error(error_msg)
            raise ValueError(error_msg)
    
    def json(self) -> str:
        """
        Сериализация в JSON строку
        
        Returns:
            str: JSON представление объекта
        """
        try:
            return json.dumps(self.to_dict())
        except Exception as e:
            logger.error(f"Failed to serialize UserAction to JSON: {str(e)}")
            raise