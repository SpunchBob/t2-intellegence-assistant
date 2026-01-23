"""
Клиент для работы с GigaChat API (без Pydantic)
"""

import requests
import json
from typing import Optional, Dict, Any, List
from datetime import datetime

from .auth import GigaChatAuth


class GigaChatClient:
    """Клиент для взаимодействия с GigaChat API"""
    
    def __init__(self, auth: GigaChatAuth):
        """
        Инициализация клиента
        
        Args:
            auth: Экземпляр GigaChatAuth для авторизации
        """
        self.auth = auth
        self.chat_url = "https://gigachat.devices.sberbank.ru/api/v1/chat/completions"
        self.session = requests.Session()
        
    def _prepare_messages(self, message: str, system_prompt: Optional[str] = None) -> List[Dict[str, str]]:
        """Подготовка списка сообщений"""
        messages = []
        
        if system_prompt:
            messages.append({
                "role": "system",
                "content": system_prompt
            })
        
        messages.append({
            "role": "user",
            "content": message
        })
        
        return messages
    
    def send_message(
        self,
        message: str,
        system_prompt: Optional[str] = None,
        model: str = "GigaChat",
        temperature: float = 0.7,
        max_tokens: int = 1024,
        stream: bool = False
    ) -> Dict[str, Any]:
        """
        Отправка сообщения в GigaChat
        
        Args:
            message: Сообщение пользователя
            system_prompt: Системный промпт (роль ассистента)
            model: Модель для использования
            temperature: Креативность ответа (0.0-2.0)
            max_tokens: Максимальное количество токенов в ответе
            stream: Потоковый режим
        
        Returns:
            Ответ от API или словарь с ошибкой
        """
        # Обновляем токен при необходимости
        token = self.auth.refresh_token_if_needed()
        if not token:
            return {
                "error": {
                    "message": "Не удалось получить токен доступа",
                    "type": "auth_error"
                }
            }
        
        # Формируем сообщения
        messages = self._prepare_messages(message, system_prompt)
        
        # Создаем тело запроса
        payload = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": stream,
            "update_interval": 0
        }
        
        # Отправляем запрос
        headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': f'Bearer {token}'
        }
        
        try:
            print("[INFO] Отправка сообщения в GigaChat...")
            response = self.session.post(
                self.chat_url,
                headers=headers,
                json=payload,
                verify=True,
                timeout=60
            )
            
            response.raise_for_status()
            response_data = response.json()
            
            print("[SUCCESS] Ответ получен успешно!")
            return response_data
            
        except requests.exceptions.RequestException as e:
            print(f"[ERROR] Ошибка при отправке сообщения: {e}")
            
            error_response = {
                "error": {
                    "message": str(e),
                    "type": "request_error"
                }
            }
            
            # Добавляем статус код, если есть
            if hasattr(e, 'response') and e.response is not None:
                error_response["error"]["status_code"] = e.response.status_code
            
            return error_response
            
        except Exception as e:
            print(f"[ERROR] Неожиданная ошибка: {e}")
            return {
                "error": {
                    "message": str(e),
                    "type": "unexpected_error"
                }
            }
    
    def extract_response_text(self, response: Dict[str, Any]) -> str:
        """
        Извлечение текста ответа из ответа API
        
        Args:
            response: Ответ от API
        
        Returns:
            Текст ответа или сообщение об ошибке
        """
        if "error" in response:
            error_msg = response["error"].get("message", "Неизвестная ошибка")
            return f"Ошибка: {error_msg}"
        
        if "choices" not in response or not response["choices"]:
            return "Пустой ответ от API"
        
        try:
            choice = response["choices"][0]
            message = choice.get("message", {})
            content = message.get("content", "")
            
            if not content:
                return "Ответ не содержит текста"
            
            return content
        except (KeyError, IndexError, AttributeError) as e:
            return f"Ошибка при обработке ответа: {e}"
    
    def get_usage_info(self, response: Dict[str, Any]) -> Dict[str, int]:
        """
        Получение информации об использовании токенов
        
        Args:
            response: Ответ от API
        
        Returns:
            Словарь с информацией об использовании
        """
        if "usage" in response and response["usage"]:
            usage = response["usage"]
            return {
                'prompt_tokens': usage.get('prompt_tokens', 0),
                'completion_tokens': usage.get('completion_tokens', 0),
                'total_tokens': usage.get('total_tokens', 0)
            }
        return {}
    
    def chat_with_history(
        self,
        messages: List[Dict[str, str]],
        model: str = "GigaChat",
        temperature: float = 0.7,
        max_tokens: int = 1024
    ) -> Dict[str, Any]:
        """
        Отправка диалога с историей сообщений
        
        Args:
            messages: Список сообщений с историей диалога
            model: Модель для использования
            temperature: Креативность ответа
            max_tokens: Максимальное количество токенов
        
        Returns:
            Ответ от API
        """
        token = self.auth.refresh_token_if_needed()
        if not token:
            return {
                "error": {
                    "message": "Не удалось получить токен доступа",
                    "type": "auth_error"
                }
            }
        
        payload = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": False,
            "update_interval": 0
        }
        
        headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': f'Bearer {token}'
        }
        
        try:
            response = self.session.post(
                self.chat_url,
                headers=headers,
                json=payload,
                verify=True,
                timeout=60
            )
            
            response.raise_for_status()
            return response.json()
            
        except requests.exceptions.RequestException as e:
            return {
                "error": {
                    "message": str(e),
                    "type": "request_error"
                }
            }
    
    def simple_chat(self, message: str) -> str:
        """
        Простой метод для отправки сообщения (без дополнительных параметров)
        
        Args:
            message: Сообщение пользователя
        
        Returns:
            Текст ответа
        """
        response = self.send_message(
            message=message,
            system_prompt="Ты полезный AI-ассистент",
            temperature=0.7,
            max_tokens=512
        )
        
        return self.extract_response_text(response)
