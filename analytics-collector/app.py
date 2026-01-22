import logging
import sys
import os
from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('analytics.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Конфигурация
RECOMMENDATION_SERVICE_URL = "http://recommendation-system:5000"
REDIS_URL = "redis://redis:6379"

# Создание FastAPI приложения
app = FastAPI(
    title="Analytics Collector API",
    description="API для сбора действий пользователей",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Импортируем модули после создания app
import models
import manager
import processor
import routes

# Инициализация менеджеров
manager_obj = manager.ConnectionManager(REDIS_URL)
processor_obj = processor.ActionProcessor(RECOMMENDATION_SERVICE_URL)

# Подключение роутера
app.include_router(routes.router)

# Сохраняем объекты в состояние приложения
app.state.manager = manager_obj
app.state.processor = processor_obj

# Middleware для добавления зависимостей
@app.middleware("http")
async def add_dependencies(request, call_next):
    request.state.manager = app.state.manager
    request.state.processor = app.state.processor
    response = await call_next(request)
    return response

@app.on_event("startup")
async def startup_event():
    try:
        logger.info("Starting Analytics Collector...")
        await manager_obj.init_redis()
        logger.info(f"[{datetime.now()}] Analytics Collector успешно запущен")
    except Exception as e:
        logger.error(f"Failed to start Analytics Collector: {str(e)}", exc_info=True)
        raise

@app.on_event("shutdown")
async def shutdown_event():
    try:
        logger.info("Shutting down Analytics Collector...")
        await manager_obj.close()
        await processor_obj.close()
        logger.info(f"[{datetime.now()}] Analytics Collector успешно остановлен")
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}", exc_info=True)

if __name__ == "__main__":
    try:
        uvicorn.run(
            app,
            host="0.0.0.0",
            port=8000,
            reload=False,
            log_level="info"
        )
    except Exception as e:
        logger.error(f"Failed to start server: {str(e)}", exc_info=True)
        raise
