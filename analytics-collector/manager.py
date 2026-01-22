import logging
from typing import Dict
from datetime import datetime
from fastapi import WebSocket
import redis.asyncio as redis

logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self, redis_url: str = "redis://redis:6379"):
        self.active_connections: Dict[str, WebSocket] = {}
        self.redis_client = None
        self.redis_url = redis_url
        logger.info("ConnectionManager initialized")

    async def connect(self, websocket: WebSocket, client_id: str) -> None:
        try:
            await websocket.accept()
            self.active_connections[client_id] = websocket
            logger.info(f"Client connected: {client_id}")
        except Exception as e:
            logger.error(f"Failed to connect client {client_id}: {str(e)}")
            raise

    def disconnect(self, client_id: str) -> None:
        if client_id in self.active_connections:
            try:
                del self.active_connections[client_id]
                logger.info(f"Client disconnected: {client_id}")
            except Exception as e:
                logger.error(f"Failed to disconnect client {client_id}: {str(e)}")

    async def init_redis(self) -> None:
        try:
            self.redis_client = await redis.from_url(
                self.redis_url, 
                decode_responses=True,
                socket_connect_timeout=5.0,
                socket_timeout=5.0,
                retry_on_timeout=True
            )
            
            await self.redis_client.ping()
            logger.info(f"[{datetime.now()}] Redis подключен успешно")
            
        except Exception as e:
            logger.error(f"Failed to initialize Redis: {str(e)}")
            self.redis_client = None
            raise

    async def close(self) -> None:
        if self.redis_client:
            try:
                await self.redis_client.close()
                logger.info("Redis connection closed")
            except Exception as e:
                logger.error(f"Failed to close Redis connection: {str(e)}")

    def get_active_connections_count(self) -> int:
        return len(self.active_connections)
