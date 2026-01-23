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
    var errorMessage: String?
    
    private let chatService = ChatService.shared
    
    init() {
        loadMessages()
    }
    
    func loadMessages() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let loadedMessages = try await chatService.loadMessages()
                await MainActor.run {
                    self.messages = loadedMessages
                    
                    // Если сообщений нет, добавляем приветственное
                    if self.messages.isEmpty {
                        self.messages.append(ChatMessage(
                            content: "Смотри, в Койн-шопе сейчас скидка 30% на 10 ГБ интернета! Успей воспользоваться акцией дня!",
                            isUser: false
                        ))
                        self.hasShopButton = true
                        
                        self.messages.append(ChatMessage(
                            content: "Привет! Я Макс, твой умный помощник. Чем могу помочь?",
                            isUser: false
                        ))
                    } else {
                        // Проверяем первое сообщение на наличие кнопки магазина
                        if let firstMessage = self.messages.first,
                           firstMessage.content.contains("Гиги-шоп") || firstMessage.content.contains("скидка") {
                            self.hasShopButton = true
                        }
                    }
                    
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Ошибка загрузки сообщений: \(error.localizedDescription)"
                    self.isLoading = false
                    
                    // Добавляем приветственное сообщение при ошибке
                    if self.messages.isEmpty {
                        self.messages.append(ChatMessage(
                            content: "Привет! Я Макс, твой умный помощник. Чем могу помочь?",
                            isUser: false
                        ))
                    }
                }
                print("Error loading messages: \(error)")
            }
        }
    }
    
    func sendMessage(_ text: String) {
        guard !text.isEmpty else { return }
        
        // Добавляем сообщение пользователя локально
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        
        // Отправляем на сервер и получаем ответ
        Task {
            do {
                // Отправляем сообщение на сервер
                let sentMessage = try await chatService.sendMessage(text)
                
                // Получаем ответ от AI
                let aiResponse = try await chatService.getAIResponse(for: text)
                
                await MainActor.run {
                    // Обновляем отправленное сообщение (если сервер вернул его с ID)
                    if let index = self.messages.firstIndex(where: { $0.id == userMessage.id }) {
                        self.messages[index] = sentMessage
                    }
                    
                    // Добавляем ответ AI
                    self.messages.append(aiResponse)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Ошибка отправки сообщения: \(error.localizedDescription)"
                    
                    // Добавляем локальный ответ при ошибке
                    let fallbackResponse = generateAIResponse(for: text)
                    self.messages.append(ChatMessage(content: fallbackResponse, isUser: false))
                }
                print("Error sending message: \(error)")
            }
        }
    }
    
    private func generateAIResponse(for userMessage: String) -> String {
        // Fallback ответы при ошибке сервера
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
    
    func clearHistory() {
        Task {
            do {
                try await chatService.clearHistory()
                await MainActor.run {
                    self.messages = []
                    self.loadMessages()
                }
            } catch {
                print("Error clearing history: \(error)")
            }
        }
    }
}
