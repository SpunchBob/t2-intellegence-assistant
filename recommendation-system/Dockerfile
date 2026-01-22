FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY recommendation_system.py .

EXPOSE 5000

CMD ["python", "recommendation_system.py"]