"""
Пример использования чата GigaChat (без Pydantic)
"""

import sys
import os

# Добавляем путь к src для импорта
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.auth import GigaChatAuth
from src.client import GigaChatClient
from src.utils import print_chat_response, save_conversation, create_system_prompt, create_user_message, create_assistant_message


def main():
    """Пример работы с чатом GigaChat"""
    
    # Ваши учетные данные (замените на реальные)
    CLIENT_ID = "ваш_client_id"
    CLIENT_SECRET = "ваш_client_secret"
    
    print("=" * 60)
    print("Пример работы с GigaChat API")
    print("=" * 60)
    
    # 1. Авторизация
    print("\n1. Авторизация...")
    auth = GigaChatAuth(client_id=CLIENT_ID, client_secret=CLIENT_SECRET)
    client = GigaChatClient(auth=auth)
    
    # 2. Простой запрос
    print("\n2. Простой запрос:")
    print("-" * 40)
    
    simple_response = client.send_message(
        message="Привет! Расскажи немного о себе",
        system_prompt="Ты полезный AI-ассистент от Сбербанка"
    )
    
    response_text = client.extract_response_text(simple_response)
    print(f"Ответ: {response_text[:100]}...")
    
    # 3. Запрос с кастомизацией
    print("\n3. Запрос с кастомизацией (творческий ответ):")
    print("-" * 40)
    
    creative_response = client.send_message(
        message="Напиши короткое стихотворение о программировании",
        system_prompt="Ты творческий поэт-программист",
        temperature=1.2,  # Более творческий ответ
        max_tokens=200
    )
    
    print_chat_response(creative_response)
    
    # 4. Запрос с историей диалога
    print("\n4. Диалог с историей:")
    print("-" * 40)
    
    messages_history = [
        create_system_prompt("Ты эксперт по искусственному интеллекту"),
        create_user_message("Что такое машинное обучение?"),
        create_assistant_message("Машинное обучение — это область искусственного интеллекта, которая позволяет компьютерам обучаться на основе данных, без явного программирования."),
        create_user_message("А чем оно отличается от глубокого обучения?")
    ]
    
    history_response = client.chat_with_history(
        messages=messages_history,
        temperature=0.8
    )
    
    history_text = client.extract_response_text(history_response)
    print(f"Ответ: {history_text}")
    
    # 5. Использование простого метода
    print("\n5. Использование простого метода:")
    print("-" * 40)
    
    simple_answer = client.simple_chat("Какая сегодня погода?")
    print(f"Ответ: {simple_answer}")
    
    # 6. Сохранение диалога
    print("\n6. Сохранение диалога:")
    print("-" * 40)
    
    # Подготавливаем данные для сохранения
    messages_for_save = [
        create_system_prompt("Ты эксперт по ИИ"),
        create_user_message("Что такое машинное обучение?"),
        create_assistant_message(history_text)
    ]
    
    filename = save_conversation(
        messages=messages_for_save,
        response=history_response
    )
    
    print("\n" + "=" * 60)
    print("Все примеры успешно выполнены!")
    print("=" * 60)


def interactive_chat():
    """Интерактивный чат с GigaChat"""
    
    CLIENT_ID = input("Введите Client ID: ").strip()
    CLIENT_SECRET = input("Введите Client Secret: ").strip()
    
    if not CLIENT_ID or not CLIENT_SECRET:
        print("[ERROR] Требуются учетные данные")
        return
    
    print("\n" + "=" * 60)
    print("Интерактивный чат с GigaChat")
    print("Введите 'exit' для выхода")
    print("Введите 'system: <prompt>' для изменения системного промпта")
    print("Введите 'raw: true/false' для показа/скрытия сырого JSON")
    print("=" * 60)
    
    # Инициализация
    auth = GigaChatAuth(client_id=CLIENT_ID, client_secret=CLIENT_SECRET)
    client = GigaChatClient(auth=auth)
    
    system_prompt = "Ты полезный и дружелюбный AI-ассистент"
    show_raw = False
    conversation_history = []
    
    while True:
        print(f"\n[System: {system_prompt}]")
        print(f"[Raw JSON: {'ON' if show_raw else 'OFF'}]")
        user_input = input("\nВы: ").strip()
        
        if user_input.lower() == 'exit':
            print("[INFO] До свидания!")
            break
        
        if user_input.startswith('system:'):
            new_prompt = user_input[7:].strip()
            if new_prompt:
                system_prompt = new_prompt
                print(f"[INFO] Системный промпт изменен на: {system_prompt}")
            continue
        
        if user_input.startswith('raw:'):
            raw_value = user_input[4:].strip().lower()
            if raw_value == 'true':
                show_raw = True
                print("[INFO] Показ сырого JSON включен")
            elif raw_value == 'false':
                show_raw = False
                print("[INFO] Показ сырого JSON выключен")
            continue
        
        # Отправляем сообщение
        response = client.send_message(
            message=user_input,
            system_prompt=system_prompt
        )
        
        # Показываем ответ
        print_chat_response(response, show_raw=show_raw)
        
        # Сохраняем в историю
        conversation_history.append(create_user_message(user_input))
        
        response_text = client.extract_response_text(response)
        if not response_text.startswith("Ошибка:"):
            conversation_history.append(create_assistant_message(response_text))
    
    # Предложение сохранить историю
    if conversation_history:
        save_option = input("\nСохранить историю диалога? (y/n): ").strip().lower()
        if save_option == 'y':
            # Создаем фиктивный ответ для сохранения
            last_response = {
                "choices": [{
                    "message": {
                        "content": conversation_history[-1]["content"] if conversation_history else "",
                        "role": "assistant"
                    }
                }],
                "usage": {},
                "model": "GigaChat"
            }
            
            save_conversation(conversation_history, last_response)


if __name__ == "__main__":
    print("Выберите режим:")
    print("1. Запуск примеров")
    print("2. Интерактивный чат")
    
    choice = input("Введите номер (1 или 2): ").strip()
    
    if choice == "1":
        main()
    elif choice == "2":
        interactive_chat()
    else:
        print("[ERROR] Неверный выбор")
