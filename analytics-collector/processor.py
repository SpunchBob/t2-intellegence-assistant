import json
import logging
from datetime import datetime
from typing import Dict, Any
import httpx

# Абсолютный импорт
import models

logger = logging.getLogger(__name__)

class ActionProcessor:
    def __init__(self, recommendation_service_url: str = "http://recommendation-system:5000"):
        self.action_aggregation = {}
        self.batch_size = 10
        self.recommendation_service_url = recommendation_service_url
        self.httpx_client = None
        logger.info("ActionProcessor initialized")

    async def get_client(self) -> httpx.AsyncClient:
        if self.httpx_client is None or self.httpx_client.is_closed:
            try:
                self.httpx_client = httpx.AsyncClient(
                    timeout=httpx.Timeout(10.0, connect=5.0),
                    limits=httpx.Limits(max_keepalive_connections=5, max_connections=10),
                    follow_redirects=True
                )
                logger.info("HTTP client created")
            except Exception as e:
                logger.error(f"Failed to create HTTP client: {str(e)}")
                raise
        
        return self.httpx_client

    async def process_action(self, action: models.UserAction, manager) -> None:
        user_id = action.user_id
        
        try:
            if manager.redis_client:
                await self._store_in_redis(user_id, action, manager)
            
            await self._aggregate_action(user_id, action)
            
            user_data = self.action_aggregation.get(user_id, {})
            if user_data.get('count', 0) >= self.batch_size:
                await self._send_to_recommendation_service(user_id)
                
        except Exception as e:
            logger.error(f"Failed to process action for user {user_id}: {str(e)}")
            raise

    async def _store_in_redis(self, user_id: str, action: models.UserAction, manager) -> None:
        try:
            key = f"user:{user_id}:actions"
            with manager.redis_client.pipeline() as pipe:
                await pipe.rpush(key, action.json())
                await pipe.expire(key, 86400)
                await pipe.execute()
            logger.debug(f"Action stored in Redis for user {user_id}")
        except Exception as e:
            logger.error(f"Failed to store action in Redis for user {user_id}: {str(e)}")
            raise

    async def _aggregate_action(self, user_id: str, action: models.UserAction) -> None:
        try:
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
            
            logger.debug(f"Action aggregated for user {user_id}: {action_key}")
            
        except Exception as e:
            logger.error(f"Failed to aggregate action for user {user_id}: {str(e)}")
            raise

    async def _send_to_recommendation_service(self, user_id: str) -> None:
        if user_id not in self.action_aggregation:
            return

        user_data = self.action_aggregation[user_id]
        actions_for_recommendation = []

        try:
            for action_key, count in user_data['actions'].items():
                try:
                    user_id_int = int(user_id) if user_id.isdigit() else abs(hash(user_id)) % 10000
                except:
                    user_id_int = abs(hash(user_id)) % 10000
                
                actions_for_recommendation.append({
                    "user_id": user_id_int,
                    "action_type": action_key,
                    "action_count": count,
                    "timestamp": datetime.now().isoformat()
                })

            if actions_for_recommendation:
                client = await self.get_client()
                async with client as http_client:
                    response = await http_client.post(
                        f"{self.recommendation_service_url}/process/batch",
                        json=actions_for_recommendation
                    )
                    
                    if response.status_code == 200:
                        logger.info(f"Sent {len(actions_for_recommendation)} actions for user {user_id}")
                        self.action_aggregation[user_id]['actions'] = {}
                        self.action_aggregation[user_id]['count'] = 0
                    else:
                        error_msg = f"Failed to send actions: {response.status_code} - {response.text}"
                        logger.error(error_msg)
                        raise Exception(error_msg)
                        
        except Exception as e:
            logger.error(f"Failed to send to recommendation service for user {user_id}: {str(e)}")
            raise

    async def close(self) -> None:
        if self.httpx_client:
            try:
                await self.httpx_client.aclose()
                logger.info("HTTP client closed")
            except Exception as e:
                logger.error(f"Failed to close HTTP client: {str(e)}")
