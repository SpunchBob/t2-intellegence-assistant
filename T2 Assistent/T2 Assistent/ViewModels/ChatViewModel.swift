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
    var isLoading: Bool = false
    var isTyping: Bool = false // Индикатор "печатает..."
    var errorMessage: String?
    
    private let chatService = ChatService.shared
    
    init() {
        loadMessages()
    }
    
    func loadMessages() {
        isLoading = true
        errorMessage = nil
        
        Task {
            // Проверяем доступность GigaChat API
            let isAPIAvailable = await chatService.checkHealth()
            
            self.messages = []
            self.isLoading = false
        }
    }
    
    func sendMessage(_ text: String) {
        guard !text.isEmpty else { return }
        guard !isTyping else { return } // Не позволяем отправлять пока AI отвечает
        
        // Добавляем сообщение пользователя локально
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        
        // Показываем индикатор "печатает..."
        isTyping = true
        
        // Получаем ответ от GigaChat
        Task {
            do {
                // Получаем ответ от AI
                let aiResponse = try await chatService.getAIResponse(for: text)
                
                await MainActor.run {
                    self.isTyping = false
                    // Добавляем ответ AI
                    self.messages.append(aiResponse)
                }
            } catch {
                await MainActor.run {
                    self.isTyping = false
                    self.errorMessage = "Не удалось получить ответ: \(error.localizedDescription)"
                    
                    // Добавляем сообщение об ошибке
                    self.messages.append(ChatMessage(
                        content: "Упс, что-то пошло не так. Попробуй спросить ещё раз! 🦊",
                        isUser: false
                    ))
                }
                print("Error getting AI response: \(error)")
            }
        }
    }
    
    func clearHistory() {
        messages = []
        loadMessages()
    }
}
