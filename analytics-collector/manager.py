"""
Менеджер WebSocket соединений и Redis клиента
Управляет активными соединениями и обеспечивает связь с Redis
"""

import asyncio
from typing import Dict
from datetime import datetime
import logging
from fastapi import WebSocket
import redis.asyncio as redis

logger = logging.getLogger(__name__)


class ConnectionManager:
    """
    Менеджер для управления WebSocket соединениями и Redis клиентом
    
    Attributes:
        active_connections (Dict[str, WebSocket]): Активные соединения
        redis_client (redis.Redis): Асинхронный Redis клиент
    """
    
    def __init__(self, redis_url: str = "redis://localhost:6379"):
        """
        Инициализация менеджера соединений
        
        Args:
            redis_url (str): URL для подключения к Redis
        """
        self.active_connections: Dict[str, WebSocket] = {}
        self.redis_client = None
        self.redis_url = redis_url
        logger.info("ConnectionManager initialized")

    async def connect(self, websocket: WebSocket, client_id: str) -> None:
        """
        Подключение нового клиента через WebSocket
        
        Args:
            websocket (WebSocket): Объект WebSocket соединения
            client_id (str): Идентификатор клиента
        """
        try:
            await websocket.accept()
            self.active_connections[client_id] = websocket
            logger.info(f"Client connected: {client_id}")
        except Exception as e:
            logger.error(f"Failed to connect client {client_id}: {str(e)}")
            raise

    def disconnect(self, client_id: str) -> None:
        """
        Отключение клиента
        
        Args:
            client_id (str): Идентификатор клиента для отключения
        """
        if client_id in self.active_connections:
            try:
                del self.active_connections[client_id]
                logger.info(f"Client disconnected: {client_id}")
            except Exception as e:
                logger.error(f"Failed to disconnect client {client_id}: {str(e)}")

    async def init_redis(self) -> None:
        """
        Инициализация Redis клиента с обработкой ошибок
        """
        try:
            # Используем контекстный менеджер для создания клиента
            self.redis_client = await redis.from_url(
                self.redis_url, 
                decode_responses=True,
                socket_connect_timeout=5.0,
                socket_timeout=5.0,
                retry_on_timeout=True
            )
            
            # Проверяем соединение
            await self.redis_client.ping()
            logger.info(f"[{datetime.now()}] Redis подключен успешно")
            
        except redis.ConnectionError as e:
            logger.error(f"Redis connection failed: {str(e)}")
            self.redis_client = None
            raise
        except Exception as e:
            logger.error(f"Failed to initialize Redis: {str(e)}")
            self.redis_client = None
            raise

    async def close(self) -> None:
        """
        Закрытие Redis соединения при завершении работы
        """
        if self.redis_client:
            try:
                await self.redis_client.close()
                logger.info("Redis connection closed")
            except Exception as e:
                logger.error(f"Failed to close Redis connection: {str(e)}")

    def get_active_connections_count(self) -> int:
        """
        Получение количества активных соединений
        
        Returns:
            int: Количество активных соединений
        """
        return len(self.active_connections)