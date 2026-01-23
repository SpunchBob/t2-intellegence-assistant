"""
Менеджер Redis для Recommendation System
Управляет подключением к Redis и операциями с данными
"""

import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional
import redis

logger = logging.getLogger(__name__)


class RedisManager:
    """
    Менеджер для работы с Redis
    
    Attributes:
        client (redis.Redis): Redis клиент
        host (str): Хост Redis
        port (int): Порт Redis
        decode_responses (bool): Декодировать ответы
    """
    
    def __init__(self, host: str = "redis", port: int = 6379, decode_responses: bool = True):
        """
        Инициализация менеджера Redis
        
        Args:
            host (str): Хост Redis сервера
            port (int): Порт Redis сервера
            decode_responses (bool): Декодировать ответы в строки
        """
        self.host = host
        self.port = port
        self.decode_responses = decode_responses
        self.client = None
        logger.info("RedisManager initialized")

    def connect(self) -> None:
        """
        Подключение к Redis с обработкой ошибок
        """
        try:
            # Создаем подключение с настройками таймаута и повторных попыток
            self.client = redis.Redis(
                host=self.host,
                port=self.port,
                decode_responses=self.decode_responses,
                socket_connect_timeout=5.0,
                socket_timeout=5.0,
                retry_on_timeout=True,
                max_connections=10
            )
            
            # Проверяем соединение
            self.client.ping()
            logger.info(f"Connected to Redis at {self.host}:{self.port}")
            
        except redis.ConnectionError as e:
            logger.error(f"Redis connection failed: {str(e)}")
            self.client = None
            raise
        except Exception as e:
            logger.error(f"Failed to connect to Redis: {str(e)}")
            self.client = None
            raise

    def save_user_profile(self, user_id: int, profile_data: Dict[str, Any], ttl: int = 604800) -> bool:
        """
        Сохранение профиля пользователя в Redis
        
        Args:
            user_id (int): Идентификатор пользователя
            profile_data (Dict): Данные профиля
            ttl (int): Время жизни в секундах (по умолчанию 7 дней)
            
        Returns:
            bool: True если сохранение успешно
        """
        if not self.client:
            logger.error("Redis client not available")
            return False
        
        try:
            key = f"user_profile:{user_id}"
            data_to_save = {
                'scores': profile_data.get('scores', {}),
                'last_updated': datetime.now().isoformat(),
                'metadata': profile_data.get('metadata', {})
            }
            
            # Используем контекстный менеджер для транзакции
            with self.client.pipeline() as pipe:
                pipe.setex(key, ttl, json.dumps(data_to_save))
                pipe.execute()
            
            logger.debug(f"Profile saved for user {user_id}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to save profile for user {user_id}: {str(e)}")
            return False

    def load_user_profile(self, user_id: int) -> Optional[Dict[str, Any]]:
        """
        Загрузка профиля пользователя из Redis
        
        Args:
            user_id (int): Идентификатор пользователя
            
        Returns:
            Optional[Dict]: Данные профиля или None если не найдены
        """
        if not self.client:
            logger.error("Redis client not available")
            return None
        
        try:
            key = f"user_profile:{user_id}"
            data = self.client.get(key)
            
            if data:
                profile_data = json.loads(data)
                logger.debug(f"Profile loaded for user {user_id}")
                return profile_data
            else:
                logger.debug(f"No profile found for user {user_id}")
                return None
                
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse profile JSON for user {user_id}: {str(e)}")
            return None
        except Exception as e:
            logger.error(f"Failed to load profile for user {user_id}: {str(e)}")
            return None

    def delete_user_profile(self, user_id: int) -> bool:
        """
        Удаление профиля пользователя из Redis
        
        Args:
            user_id (int): Идентификатор пользователя
            
        Returns:
            bool: True если удаление успешно
        """
        if not self.client:
            logger.error("Redis client not available")
            return False
        
        try:
            key = f"user_profile:{user_id}"
            result = self.client.delete(key)
            if result:
                logger.info(f"Profile deleted for user {user_id}")
                return True
            else:
                logger.debug(f"No profile to delete for user {user_id}")
                return False
                
        except Exception as e:
            logger.error(f"Failed to delete profile for user {user_id}: {str(e)}")
            return False

    def health_check(self) -> Dict[str, Any]:
        """
        Проверка здоровья Redis соединения
        
        Returns:
            Dict: Статус соединения с Redis
        """
        try:
            if self.client and self.client.ping():
                return {
                    'status': 'connected',
                    'host': self.host,
                    'port': self.port,
                    'timestamp': datetime.now().isoformat()
                }
            else:
                return {
                    'status': 'disconnected',
                    'host': self.host,
                    'port': self.port,
                    'timestamp': datetime.now().isoformat()
                }
                
        except Exception as e:
            logger.error(f"Redis health check failed: {str(e)}")
            return {
                'status': 'error',
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }

    def close(self) -> None:
        """
        Закрытие Redis соединения
        """
        if self.client:
            try:
                self.client.close()
                logger.info("Redis connection closed")
            except Exception as e:
                logger.error(f"Failed to close Redis connection: {str(e)}")