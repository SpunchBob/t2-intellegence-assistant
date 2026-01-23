# Базовый образ Python
FROM python:3.11-alpine

# Рабочая директория
WORKDIR /app

# Установка системных зависимостей (только необходимые)
RUN apk add --no-cache curl

# Копируем файл с зависимостями
COPY requirements.txt .

# Устанавливаем Python зависимости
RUN pip install --no-cache-dir -r requirements.txt

# Копируем весь проект
COPY . .

# Создаем пользователя для безопасности
RUN adduser -D -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Команда по умолчанию
CMD ["python", "examples/example_chat.py"]
