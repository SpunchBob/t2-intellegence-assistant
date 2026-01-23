"""
Простой тест для проверки работы GigaChat API
(минимальный код, как в исходном примере)
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.auth import simple_token_generation


def test_token_generation():
    """Простой тест генерации токена"""
    print("=" * 50)
    print("Тест генерации токена GigaChat API")
    print("=" * 50)
    
    # Получаем учетные данные от пользователя
    client_id = input("Введите Client ID: ").strip()
    client_secret = input("Введите Client Secret: ").strip()
    
    if not client_id or not client_secret:
        print("❌ Требуются учетные данные")
        return
    
    print("\n[INFO] Генерация токена...")
    
    result = simple_token_generation(client_id, client_secret)
    
    print("\n" + "=" * 50)
    
    if result['success']:
        print("✅ Токен успешно получен!")
        print(f"\nДетали:")
        print(f"  Токен: {result['token'][:30]}...")
        print(f"  Тип: {result.get('token_type', 'N/A')}")
        print(f"  Срок действия: {result.get('expires_in', 'N/A')} сек")
        
        # Сохраняем токен в файл (опционально)
        save_token = input("\nСохранить токен в файл? (y/n): ").strip().lower()
        if save_token == 'y':
            with open("token.txt", "w") as f:
                f.write(result['token'])
            print("✅ Токен сохранен в token.txt")
    else:
        print("❌ Ошибка при получении токена")
        print(f"\nДетали ошибки:")
        print(f"  Сообщение: {result['error']}")
        print(f"  Код статуса: {result.get('status_code', 'N/A')}")
    
    print("\n" + "=" * 50)


def quick_test():
    """Быстрый тест с жестко заданными credentials"""
    # Замените на свои реальные данные
    TEST_CLIENT_ID = "ваш_client_id"
    TEST_CLIENT_SECRET = "ваш_client_secret"
    
    print("[INFO] Быстрый тест...")
    
    result = simple_token_generation(TEST_CLIENT_ID, TEST_CLIENT_SECRET)
    
    if result['success']:
        print(f"✅ Тест пройден! Токен получен: {result['token'][:20]}...")
        return result['token']
    else:
        print(f"❌ Тест не пройден: {result['error']}")
        return None


if __name__ == "__main__":
    print("Выберите тест:")
    print("1. Полный тест с вводом данных")
    print("2. Быстрый тест (требует редактирования кода)")
    
    choice = input("Введите номер: ").strip()
    
    if choice == "1":
        test_token_generation()
    elif choice == "2":
        quick_test()
    else:
        print("Неверный выбор")
