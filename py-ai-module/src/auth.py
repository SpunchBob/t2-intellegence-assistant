"""
Модуль для работы с авторизацией GigaChat API (без Pydantic)
"""

import uuid
import base64
import requests
import json
from typing import Optional, Dict, Any
from datetime import datetime, timedelta


class GigaChatAuth:
    """Класс для управления авторизацией и токенами GigaChat API"""
    
    def __init__(self, client_id: str, client_secret: str):
        """
        Инициализация клиента авторизации
        
        Args:
            client_id: Client ID из личного кабинета GigaChat
            client_secret: Client Secret из личного кабинета GigaChat
        """
        self.client_id = client_id
        self.client_secret = client_secret
        self.access_token = None
        self.token_expires_at = None
        self.auth_url = "https://ngw.devices.sberbank.ru:9443/api/v2/oauth"
        self.token_type = None
        self.scope = None
        
    def _generate_rq_uid(self) -> str:
        """Генерация уникального RqUID"""
        return str(uuid.uuid4())
    
    def _get_basic_auth_header(self) -> str:
        """Создание Basic Auth заголовка"""
        credentials = f"{self.client_id}:{self.client_secret}"
        encoded_credentials = base64.b64encode(credentials.encode()).decode()
        return f"Basic {encoded_credentials}"
    
    def generate_token(self, force_refresh: bool = False) -> Optional[str]:
        """
        Генерация/получение токена доступа
        
        Args:
            force_refresh: Принудительное обновление токена
        
        Returns:
            Токен доступа или None в случае ошибки
        """
        # Проверяем, есть ли действующий токен
        if not force_refresh and self.access_token and self.token_expires_at:
            if datetime.now() < self.token_expires_at:
                print(f"[INFO] Используется существующий токен")
                return self.access_token
        
        # Генерируем новый токен
        payload = {
            'scope': 'GIGACHAT_API_PERS'
        }
        
        headers = {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
            'RqUID': self._generate_rq_uid(),
            'Authorization': self._get_basic_auth_header()
        }
        
        try:
            print("[INFO] Отправка запроса на получение токена...")
            response = requests.post(
                self.auth_url, 
                headers=headers, 
                data=payload,
                verify=True,
                timeout=30
            )
            
            if response.status_code == 200:
                token_data = response.json()
                self.access_token = token_data.get('access_token')
                self.token_type = token_data.get('token_type')
                self.scope = token_data.get('scope')
                
                # Вычисляем время истечения токена
                expires_in = token_data.get('expires_in', 1800)  # 30 минут по умолчанию
                self.token_expires_at = datetime.now() + timedelta(seconds=expires_in - 60)
                
                print(f"[SUCCESS] Токен успешно получен!")
                print(f"[INFO] Действителен до: {self.token_expires_at.strftime('%H:%M:%S')}")
                
                return self.access_token
            else:
                print(f"[ERROR] Ошибка при получении токена. Статус: {response.status_code}")
                print(f"[ERROR] Ответ сервера: {response.text}")
                return None
                
        except requests.exceptions.RequestException as e:
            print(f"[ERROR] Сетевая ошибка при получении токена: {e}")
            return None
        except Exception as e:
            print(f"[ERROR] Неожиданная ошибка: {e}")
            return None
    
    def is_token_valid(self) -> bool:
        """Проверка действительности токена"""
        if not self.access_token or not self.token_expires_at:
            return False
        return datetime.now() < self.token_expires_at
    
    def get_token_info(self) -> Dict[str, Any]:
        """Получение информации о текущем токене"""
        expires_in_seconds = 0
        if self.token_expires_at and self.is_token_valid():
            expires_in_seconds = (self.token_expires_at - datetime.now()).total_seconds()
        
        return {
            'has_token': self.access_token is not None,
            'is_valid': self.is_token_valid(),
            'expires_at': self.token_expires_at.isoformat() if self.token_expires_at else None,
            'expires_in_seconds': int(expires_in_seconds),
            'token_type': self.token_type,
            'scope': self.scope,
            'client_id': self.client_id
        }
    
    def refresh_token_if_needed(self) -> Optional[str]:
        """Обновление токена, если он истек или скоро истечет"""
        if not self.is_token_valid():
            print("[WARNING] Токен истек или недействителен. Обновление...")
            return self.generate_token(force_refresh=True)
        
        # Проверяем, скоро ли истекает токен (менее 5 минут)
        if self.token_expires_at:
            time_remaining = (self.token_expires_at - datetime.now()).total_seconds()
            if time_remaining < 300:  # 5 минут
                print(f"[WARNING] Токен скоро истекает (осталось {int(time_remaining)} сек). Обновление...")
                return self.generate_token(force_refresh=True)
        
        return self.access_token


def simple_token_generation(client_id: str, client_secret: str) -> Dict[str, Any]:
    """
    Простая функция генерации токена (как в исходном примере)
    
    Args:
        client_id: Client ID
        client_secret: Client Secret
    
    Returns:
        Словарь с результатом
    """
    url = "https://ngw.devices.sberbank.ru:9443/api/v2/oauth"
    
    payload = {
        'scope': 'GIGACHAT_API_PERS'
    }
    
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'RqUID': str(uuid.uuid4()),
    }
    
    # Формируем Basic Auth заголовок
    credentials = f"{client_id}:{client_secret}"
    encoded_credentials = base64.b64encode(credentials.encode()).decode()
    headers['Authorization'] = f"Basic {encoded_credentials}"
    
    result = {
        'success': False,
        'token': None,
        'error': None,
        'status_code': None
    }
    
    try:
        response = requests.post(url, headers=headers, data=payload, verify=True, timeout=30)
        result['status_code'] = response.status_code
        
        if response.status_code == 200:
            token_data = response.json()
            result['success'] = True
            result['token'] = token_data.get('access_token')
            result['token_type'] = token_data.get('token_type')
            result['expires_in'] = token_data.get('expires_in')
        else:
            result['error'] = f"HTTP {response.status_code}: {response.text}"
            
    except requests.exceptions.RequestException as e:
        result['error'] = f"Request error: {str(e)}"
    except Exception as e:
        result['error'] = f"Unexpected error: {str(e)}"
    
    return result
