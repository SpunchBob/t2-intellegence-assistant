"""
Вспомогательные функции для работы с GigaChat API (без Pydantic)
"""

import json
from typing import Dict, Any, List
from datetime import datetime


def print_chat_response(response: Dict[str, Any], show_raw: bool = False, show_usage: bool = True) -> None:
    """
    Красивая печать ответа от чата
    
    Args:
        response: Ответ от API
        show_raw: Показывать сырой JSON ответ
        show_usage: Показывать информацию об использовании токенов
    """
    print("\n" + "=" * 80)
    
    if show_raw:
        print("[RAW JSON RESPONSE]:")
        print(json.dumps(response, ensure_ascii=False, indent=2))
        print("-" * 80)
    
    if 'error' in response:
        print("[ERROR]:")
        error_msg = response['error'].get('message', 'Неизвестная ошибка')
        error_type = response['error'].get('type', 'unknown')
        print(f"  Тип: {error_type}")
        print(f"  Сообщение: {error_msg}")
        
        if 'status_code' in response['error']:
            print(f"  Код статуса: {response['error']['status_code']}")
        
        print("=" * 80)
        return
    
    # Извлекаем текст ответа
    choices = response.get('choices', [])
    if not choices:
        print("[WARNING]: Ответ не содержит вариантов")
        print("=" * 80)
        return
    
    choice = choices[0]
    message = choice.get('message', {})
    content = message.get('content', '')
    role = message.get('role', 'assistant')
    
    if content:
        print(f"[{role.upper()}]:")
        print("-" * 80)
        print(content)
        print("-" * 80)
    else:
        print("[WARNING]: Ответ не содержит текста")
    
    # Показываем статистику использования токенов
    if show_usage:
        usage = response.get('usage', {})
        if usage:
            print("[TOKEN USAGE]:")
            print(f"  Prompt tokens: {usage.get('prompt_tokens', 0)}")
            print(f"  Completion tokens: {usage.get('completion_tokens', 0)}")
            print(f"  Total tokens: {usage.get('total_tokens', 0)}")
    
    # Информация о модели
    model = response.get('model', 'Unknown')
    print(f"[MODEL]: {model}")
    
    # ID ответа
    response_id = response.get('id', 'N/A')
    print(f"[RESPONSE ID]: {response_id}")
    
    print("=" * 80)


def save_conversation(
    messages: List[Dict[str, str]],
    response: Dict[str, Any],
    filename: str = None
) -> str:
    """
    Сохранение диалога в файл
    
    Args:
        messages: История сообщений
        response: Ответ от API
        filename: Имя файла (автогенерация, если не указано)
    
    Returns:
        Имя сохраненного файла
    """
    if filename is None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"conversation_{timestamp}.json"
    
    conversation = {
        "timestamp": datetime.now().isoformat(),
        "messages": messages,
        "response": response,
        "usage": response.get('usage', {}),
        "model": response.get('model', 'GigaChat')
    }
    
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(conversation, f, ensure_ascii=False, indent=2)
        
        print(f"[INFO] Диалог сохранен в файл: {filename}")
        return filename
    except Exception as e:
        print(f"[ERROR] Не удалось сохранить файл: {e}")
        return ""


def load_conversation(filename: str) -> Dict[str, Any]:
    """
    Загрузка диалога из файла
    
    Args:
        filename: Имя файла
    
    Returns:
        Загруженный диалог
    """
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            conversation = json.load(f)
        print(f"[INFO] Диалог загружен из файла: {filename}")
        return conversation
    except FileNotFoundError:
        print(f"[ERROR] Файл не найден: {filename}")
        return {}
    except json.JSONDecodeError as e:
        print(f"[ERROR] Ошибка декодирования JSON: {e}")
        return {}
    except Exception as e:
        print(f"[ERROR] Ошибка загрузки файла: {e}")
        return {}


def validate_credentials(client_id: str, client_secret: str) -> bool:
    """
    Валидация учетных данных
    
    Args:
        client_id: Client ID
        client_secret: Client Secret
    
    Returns:
        True если credentials валидны
    """
    if not client_id or not client_secret:
        print("[ERROR] Client ID и Client Secret не могут быть пустыми")
        return False
    
    if len(client_id) < 10:
        print("[WARNING] Client ID слишком короткий")
    
    if len(client_secret) < 10:
        print("[WARNING] Client Secret слишком короткий")
    
    return True


def format_message(role: str, content: str) -> Dict[str, str]:
    """
    Форматирование сообщения в правильный формат
    
    Args:
        role: Роль (system, user, assistant)
        content: Текст сообщения
    
    Returns:
        Форматированное сообщение
    """
    return {
        "role": role,
        "content": content
    }


def create_system_prompt(prompt_text: str) -> Dict[str, str]:
    """Создание системного промпта"""
    return format_message("system", prompt_text)


def create_user_message(message_text: str) -> Dict[str, str]:
    """Создание сообщения пользователя"""
    return format_message("user", message_text)


def create_assistant_message(message_text: str) -> Dict[str, str]:
    """Создание сообщения ассистента"""
    return format_message("assistant", message_text)
