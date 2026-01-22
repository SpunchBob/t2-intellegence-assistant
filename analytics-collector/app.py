import asyncio
import json
from datetime import datetime
from typing import Dict, Any
from dataclasses import dataclass, asdict
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import httpx  # ← ЗАМЕНИЛИ aiohttp на httpx
import redis.asyncio as redis

# FastAPI app
app = FastAPI(
    title="Analytics Collector API",
    description="API для сбора действий пользователей",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Конфигурация
RECOMMENDATION_SERVICE_URL = "http://localhost:5000"
REDIS_URL = "redis://localhost:6379"

# Модель данных
@dataclass
class UserAction:
    user_id: str
    action: str
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'UserAction':
        if not isinstance(data, dict):
            raise ValueError("Data must be a dictionary")
        
        user_id = data.get("user_id")
        action = data.get("action")
        
        if not user_id:
            raise ValueError("user_id is required")
        if not action:
            raise ValueError("action is required")
        
        return cls(
            user_id=str(user_id),
            action=str(action)
        )
    
    def json(self) -> str:
        return json.dumps(self.to_dict())

# Менеджер соединений
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.redis_client = None

    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket

    def disconnect(self, client_id: str):
        if client_id in self.active_connections:
            del self.active_connections[client_id]

    async def init_redis(self):
        self.redis_client = redis.from_url(REDIS_URL, decode_responses=True)
        await self.redis_client.ping()
        print(f"[{datetime.now()}] Redis подключен")

manager = ConnectionManager()

# Обработчик действий
class ActionProcessor:
    def __init__(self):
        self.action_aggregation = {}
        self.batch_size = 10
        self.httpx_client = None  # HTTP-клиент

    async def get_client(self):
        """Создание/получение httpx клиента"""
        if self.httpx_client is None:
            self.httpx_client = httpx.AsyncClient(timeout=5.0)
        return self.httpx_client

    async def process_action(self, action: UserAction):
        user_id = action.user_id

        await self._store_in_redis(user_id, action)
        await self._aggregate_action(user_id, action)
        await self._send_to_recommendation_service(user_id)

    async def _store_in_redis(self, user_id: str, action: UserAction):
        if manager.redis_client:
            key = f"user:{user_id}:actions"
            await manager.redis_client.rpush(key, action.json())
            await manager.redis_client.expire(key, 86400)

    async def _aggregate_action(self, user_id: str, action: UserAction):
        if user_id not in self.action_aggregation:
            self.action_aggregation[user_id] = {
                'actions': {},
                'count': 0
            }

        action_key = action.action

        if action_key not in self.action_aggregation[user_id]['actions']:
            self.action_aggregation[user_id]['actions'][action_key] = 0

        self.action_aggregation[user_id]['actions'][action_key] += 1
        self.action_aggregation[user_id]['count'] += 1

    async def _send_to_recommendation_service(self, user_id: str):
        if user_id in self.action_aggregation:
            user_data = self.action_aggregation[user_id]

            actions_for_recommendation = []
            for action_key, count in user_data['actions'].items():
                try:
                    user_id_int = int(user_id) if user_id.isdigit() else abs(hash(user_id)) % 10000
                except:
                    user_id_int = abs(hash(user_id)) % 10000
                
                actions_for_recommendation.append({
                    "user_id": user_id_int,
                    "action": action_key,
                    "action_count": count,
                    "timestamp": datetime.now().isoformat()
                })

            if actions_for_recommendation:
                try:
                    client = await self.get_client()
                    response = await client.post(
                        f"{RECOMMENDATION_SERVICE_URL}/process",
                        json=actions_for_recommendation
                    )
                    
                    if response.status_code == 200:
                        print(f"[{datetime.now()}] Отправлено {len(actions_for_recommendation)} действий для пользователя {user_id}")
                        self.action_aggregation[user_id]['actions'] = {}
                    else:
                        print(f"[{datetime.now()}] Ошибка отправки: {response.status_code}")
                        
                except Exception as e:
                    print(f"[{datetime.now()}] Ошибка: {e}")

    async def close(self):
        """Закрытие httpx клиента"""
        if self.httpx_client:
            await self.httpx_client.aclose()

processor = ActionProcessor()

# WebSocket endpoint
@app.websocket("/ws/analytics/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    await manager.connect(websocket, client_id)
    print(f"[{datetime.now()}] Клиент подключен: {client_id}")

    try:
        while True:
            data = await websocket.receive_text()

            try:
                json_data = json.loads(data)
                action = UserAction.from_dict(json_data)
                await processor.process_action(action)

                await websocket.send_text(json.dumps({
                    "status": "success",
                    "message": "Действие обработано",
                    "timestamp": datetime.now().isoformat()
                }))

            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({
                    "status": "error",
                    "message": "Невалидный JSON"
                }))
            except ValueError as e:
                await websocket.send_text(json.dumps({
                    "status": "error",
                    "message": str(e)
                }))
            except Exception as e:
                print(f"[{datetime.now()}] Ошибка обработки: {e}")
                await websocket.send_text(json.dumps({
                    "status": "error",
                    "message": "Внутренняя ошибка сервера"
                }))
                
    except WebSocketDisconnect:
        manager.disconnect(client_id)
        print(f"[{datetime.now()}] Клиент отключен: {client_id}")

# REST endpoints
@app.get("/stats/{user_id}")
async def get_user_stats(user_id: str):
    if manager.redis_client:
        key = f"user:{user_id}:actions"
        actions = await manager.redis_client.lrange(key, 0, -1)

        stats = {
            "user_id": user_id,
            "total_actions": len(actions),
            "action_types": {},
            "last_action": None
        }

        for action_json in actions[-50:]:
            try:
                action_data = json.loads(action_json)
                action_type = action_data.get("action", "unknown")
                stats["action_types"][action_type] = stats["action_types"].get(action_type, 0) + 1
            except:
                continue

        return stats

    return {"error": "Redis не доступен"}

@app.get("/health")
async def health_check():
    redis_status = "connected" if manager.redis_client else "disconnected"
    
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "connections": len(manager.active_connections),
        "redis": redis_status,
        "service": "analytics-collector"
    }

@app.on_event("startup")
async def startup_event():
    await manager.init_redis()
    print(f"[{datetime.now()}] Analytics Collector запущен")

@app.on_event("shutdown")
async def shutdown_event():
    """Очистка ресурсов при завершении"""
    await processor.close()
    print(f"[{datetime.now()}] Analytics Collector остановлен")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)