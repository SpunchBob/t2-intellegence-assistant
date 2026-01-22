"""
Маршруты API для Analytics Collector
Определяет WebSocket и REST эндпоинты
"""

import json
import logging
from datetime import datetime
from fastapi import WebSocket, WebSocketDisconnect, APIRouter, Depends, Request
from .models import UserAction

logger = logging.getLogger(__name__)

router = APIRouter()


async def get_manager(request: Request):
    """Получение менеджера из состояния запроса"""
    return request.state.manager


async def get_processor(request: Request):
    """Получение процессора из состояния запроса"""
    return request.state.processor


@router.websocket("/ws/analytics/{client_id}")
async def websocket_endpoint(
    websocket: WebSocket, 
    client_id: str, 
    manager = Depends(get_manager),
    processor = Depends(get_processor)
):
    """
    WebSocket эндпоинт для получения действий пользователя в реальном времени
    
    Args:
        websocket (WebSocket): WebSocket соединение
        client_id (str): Идентификатор клиента
        manager (ConnectionManager): Менеджер соединений
        processor (ActionProcessor): Процессор действий
    """
    await manager.connect(websocket, client_id)
    logger.info(f"WebSocket client connected: {client_id}")

    try:
        while True:
            # Получаем данные от клиента
            data = await websocket.receive_text()

            try:
                # Парсим и валидируем JSON
                json_data = json.loads(data)
                action = UserAction.from_dict(json_data)
                
                # Обрабатываем действие
                await processor.process_action(action, manager)

                # Отправляем подтверждение
                await websocket.send_text(json.dumps({
                    "status": "success",
                    "message": "Действие обработано",
                    "timestamp": datetime.now().isoformat()
                }))

            except json.JSONDecodeError as e:
                error_msg = "Невалидный JSON"
                logger.error(f"{error_msg} from client {client_id}: {str(e)}")
                await websocket.send_text(json.dumps({
                    "status": "error",
                    "message": error_msg
                }))
                
            except ValueError as e:
                error_msg = str(e)
                logger.error(f"Validation error from client {client_id}: {error_msg}")
                await websocket.send_text(json.dumps({
                    "status": "error",
                    "message": error_msg
                }))
                
            except Exception as e:
                error_msg = "Внутренняя ошибка сервера"
                logger.error(f"Processing error for client {client_id}: {str(e)}", exc_info=True)
                await websocket.send_text(json.dumps({
                    "status": "error",
                    "message": error_msg
                }))
                
    except WebSocketDisconnect:
        manager.disconnect(client_id)
        logger.info(f"WebSocket client disconnected: {client_id}")
    except Exception as e:
        logger.error(f"Unexpected error in WebSocket for client {client_id}: {str(e)}", exc_info=True)
        manager.disconnect(client_id)


@router.get("/stats/{user_id}")
async def get_user_stats(
    user_id: str,
    manager = Depends(get_manager)
):
    """
    Получение статистики по действиям пользователя
    
    Args:
        user_id (str): Идентификатор пользователя
        manager (ConnectionManager): Менеджер соединений
        
    Returns:
        Dict: Статистика действий пользователя
    """
    try:
        if not manager.redis_client:
            logger.error("Redis not available for stats request")
            return {"error": "Redis не доступен"}

        key = f"user:{user_id}:actions"
        
        # Используем контекстный менеджер для пайплайна Redis
        async with manager.redis_client.pipeline() as pipe:
            pipe.lrange(key, 0, -1)
            pipe.llen(key)
            actions, total_count = await pipe.execute()

        stats = {
            "user_id": user_id,
            "total_actions": total_count,
            "action_types": {},
            "last_action": None
        }

        # Анализируем последние 50 действий
        for action_json in actions[-50:]:
            try:
                action_data = json.loads(action_json)
                action_type = action_data.get("action", "unknown")
                stats["action_types"][action_type] = stats["action_types"].get(action_type, 0) + 1
            except Exception as e:
                logger.warning(f"Failed to parse action JSON for user {user_id}: {str(e)}")
                continue

        logger.info(f"Stats retrieved for user {user_id}")
        return stats

    except Exception as e:
        logger.error(f"Failed to get stats for user {user_id}: {str(e)}", exc_info=True)
        return {"error": "Ошибка при получении статистики"}


@router.get("/health")
async def health_check(manager = Depends(get_manager)):
    """
    Проверка здоровья сервиса
    
    Returns:
        Dict: Статус здоровья сервиса
    """
    try:
        redis_status = "connected" if manager.redis_client else "disconnected"
        
        health_data = {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "connections": manager.get_active_connections_count(),
            "redis": redis_status,
            "service": "analytics-collector"
        }
        
        logger.debug("Health check completed")
        return health_data
        
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}", exc_info=True)
        return {
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }