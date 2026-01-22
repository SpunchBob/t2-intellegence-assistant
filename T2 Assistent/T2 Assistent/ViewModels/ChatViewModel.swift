//
//  ChatViewModel.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import SwiftUI

@Observable
@MainActor
class ChatViewModel {
    var messages: [ChatMessage] = []
    var hasShopButton: Bool = false // Для первого сообщения с кнопкой магазина
    
    init() {
        // Первое сообщение с предложением магазина
        messages.append(ChatMessage(
            content: "Смотри, в Гиги-шопе сейчас скидка 30% на 10 ГБ интернета! Успей воспользоваться акцией дня!",
            isUser: false
        ))
        hasShopButton = true
        
        // Второе приветственное сообщение
        messages.append(ChatMessage(
            content: "Привет! Я Макс, твой умный помощник. Чем могу помочь?",
            isUser: false
        ))
    }
    
    func sendMessage(_ text: String) {
        // Добавляем сообщение пользователя
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        
        // Имитация ответа AI (здесь будет интеграция с реальным AI)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // Задержка 0.5 секунды
            
            let aiResponse = generateAIResponse(for: text)
            let aiMessage = ChatMessage(content: aiResponse, isUser: false)
            messages.append(aiMessage)
        }
    }
    
    private func generateAIResponse(for userMessage: String) -> String {
        // Временная заглушка для ответов AI
        // Здесь будет реальная интеграция с AI сервисом
        let lowercased = userMessage.lowercased()
        
        if lowercased.contains("привет") || lowercased.contains("здравствуй") {
            return "Привет! Рад вас видеть. Как дела?"
        } else if lowercased.contains("тариф") || lowercased.contains("пакет") {
            return "Я могу помочь вам выбрать подходящий тариф. Какие у вас потребности в интернете и звонках?"
        } else if lowercased.contains("баланс") {
            return "Для проверки баланса используйте приложение Tele2 или отправьте USSD запрос *100#"
        } else {
            return "Понял вас. Я помогу разобраться с вашим вопросом. Можете уточнить детали?"
        }
    }
}
