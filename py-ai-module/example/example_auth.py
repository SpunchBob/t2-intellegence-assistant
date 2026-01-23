"""
Пример использования модуля авторизации (без Pydantic)
"""

import sys
import os

# Добавляем путь к src для импорта
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.auth import GigaChatAuth, simple_token_generation
from src.utils import validate_credentials


def main():
    """Пример работы с авторизацией"""
    
    # Ваши учетные данные (замените на реальные)
    CLIENT_ID = "ваш_client_id"
    CLIENT_SECRET = "ваш_client_secret"
    
    # Валидация credentials
    if not validate_credentials(CLIENT_ID, CLIENT_SECRET):
        print("Пожалуйста, укажите корректные учетные данные")
        return
    
    print("=" * 60)
    print("Пример работы с авторизацией GigaChat API")
    print("=" * 60)
    
    # 1. Использование простой функции (как в исходном примере)
    print("\n1. Использование простой функции:")
    print("-" * 40)
    
    result = simple_token_generation(CLIENT_ID, CLIENT_SECRET)
    if result['success']:
        print(f"Токен получен: {result['token'][:20]}...")
        print(f"Тип токена: {result.get('token_type')}")
        print(f"Срок действия: {result.get('expires_in')} секунд")
    else:
        print(f"Ошибка: {result['error']}")
    
    # 2. Использование класса GigaChatAuth
    print("\n2. Использование класса GigaChatAuth:")
    print("-" * 40)
    
    # Создаем экземпляр авторизации
    auth = GigaChatAuth(client_id=CLIENT_ID, client_secret=CLIENT_SECRET)
    
    # Получаем токен
    token = auth.generate_token()
    
    if not token:
        print("Не удалось получить токен. Завершение работы.")
        return
    
    # Показываем информацию о токене
    print("\n3. Информация о токене:")
    print("-" * 40)
    token_info = auth.get_token_info()
    
    for key, value in token_info.items():
        print(f"  {key}: {value}")
    
    # Проверяем, можно ли использовать существующий токен
    print("\n4. Проверка повторного использования токена:")
    print("-" * 40)
    existing_token = auth.generate_token()  # Должен вернуть существующий
    print(f"  Использован существующий токен: {existing_token[:20]}...")
    
    # Принудительное обновление
    print("\n5. Принудительное обновление токена:")
    print("-" * 40)
    new_token = auth.generate_token(force_refresh=True)
    if new_token:
        print(f"  Новый токен: {new_token[:20]}...")
    
    # Проверка автоматического обновления
    print("\n6. Проверка автоматического обновления:")
    print("-" * 40)
    print("  Симуляция ситуации, когда токен скоро истечет...")
    # Устанавливаем время истечения в прошлое
    auth.token_expires_at = None
    refreshed_token = auth.refresh_token_if_needed()
    if refreshed_token:
        print(f"  Токен успешно обновлен: {refreshed_token[:20]}...")
    
    print("\n" + "=" * 60)
    print("Пример завершен!")
    print("=" * 60)


if __name__ == "__main__":
    main()
