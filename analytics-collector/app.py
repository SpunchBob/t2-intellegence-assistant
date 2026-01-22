"""
Основной файл приложения Analytics Collector
Объединяет все модули и запускает сервер
"""

import logging
from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from .routes import router
from .manager import ConnectionManager
from .processor import ActionProcessor

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
RECOMMENDATION_SERVICE_URL = "http://recommendation-service:5000"
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

# Инициализация менеджеров
manager = ConnectionManager(REDIS_URL)
processor = ActionProcessor(RECOMMENDATION_SERVICE_URL)

# Подключение роутера
app.include_router(router)


@app.on_event("startup")
async def startup_event():
    """
    Инициализация при старте сервиса
    """
    try:
        logger.info("Starting Analytics Collector...")
        
        # Инициализация Redis
        await manager.init_redis()
        
        logger.info(f"[{datetime.now()}] Analytics Collector успешно запущен")
        
    except Exception as e:
        logger.error(f"Failed to start Analytics Collector: {str(e)}", exc_info=True)
        raise


@app.on_event("shutdown")
async def shutdown_event():
    """
    Очистка ресурсов при завершении работы
    """
    try:
        logger.info("Shutting down Analytics Collector...")
        
        # Закрываем Redis соединение
        await manager.close()
        
        # Закрываем HTTP клиент
        await processor.close()
        
        logger.info(f"[{datetime.now()}] Analytics Collector успешно остановлен")
        
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}", exc_info=True)


# Добавляем зависимости для инжекции
@app.middleware("http")
async def add_dependencies(request, call_next):
    """
    Middleware для добавления зависимостей в запрос
    """
    request.state.manager = manager
    request.state.processor = processor
    response = await call_next(request)
    return response


if __name__ == "__main__":
    """
    Точка входа для запуска сервера напрямую
    """
    try:
        uvicorn.run(
            "app:app",
            host="0.0.0.0",
            port=8000,
            reload=True,
            log_level="info"
        )
    except Exception as e:
        logger.error(f"Failed to start server: {str(e)}", exc_info=True)
        raise