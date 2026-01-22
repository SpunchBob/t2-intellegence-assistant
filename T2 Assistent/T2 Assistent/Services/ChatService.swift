//
//  ChatService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

@MainActor
class ChatService {
    static let shared = ChatService()
    
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // Загрузка истории сообщений
    func loadMessages(limit: Int = 50, offset: Int = 0) async throws -> [ChatMessage] {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<[ChatMessage]>(
        //     endpoint: "/api/v1/chat/messages?limit=\(limit)&offset=\(offset)",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Временные данные
        return [
            ChatMessage(
                content: "Привет! Я Макс, твой умный помощник. Чем могу помочь?",
                isUser: false
            )
        ]
    }
    
    // Отправка сообщения пользователя
    func sendMessage(_ text: String) async throws -> ChatMessage {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<ChatMessage>(
        //     endpoint: "/api/v1/chat/send",
        //     method: "POST",
        //     body: ["message": text],
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 300_000_000)
        return ChatMessage(content: text, isUser: true)
    }
    
    // Получение ответа от AI
    func getAIResponse(for message: String) async throws -> ChatMessage {
        // TODO: Замените на реальный endpoint для AI
        // return try await networkService.request<ChatMessage>(
        //     endpoint: "/api/v1/chat/ai-response",
        //     method: "POST",
        //     body: ["message": message],
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        // Имитация задержки AI ответа
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Временная заглушка для ответов AI
        let lowercased = message.lowercased()
        let response: String
        
        if lowercased.contains("привет") || lowercased.contains("здравствуй") {
            response = "Привет! Рад вас видеть. Как дела?"
        } else if lowercased.contains("тариф") || lowercased.contains("пакет") {
            response = "Я могу помочь вам выбрать подходящий тариф. Какие у вас потребности в интернете и звонках?"
        } else if lowercased.contains("баланс") {
            response = "Для проверки баланса используйте приложение Tele2 или отправьте USSD запрос *100#"
        } else {
            response = "Понял вас. Я помогу разобраться с вашим вопросом. Можете уточнить детали?"
        }
        
        return ChatMessage(content: response, isUser: false)
    }
    
    // Отправка голосового сообщения
    func sendVoiceMessage(_ audioData: Data) async throws -> ChatMessage {
        // TODO: Замените на реальный endpoint
        // let base64Audio = audioData.base64EncodedString()
        // return try await networkService.request<ChatMessage>(
        //     endpoint: "/api/v1/chat/send-voice",
        //     method: "POST",
        //     body: ["audio": base64Audio],
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 1_500_000_000)
        return ChatMessage(content: "Голосовое сообщение обработано", isUser: false)
    }
    
    // Очистка истории чата
    func clearHistory() async throws {
        // TODO: Замените на реальный endpoint
        // _ = try await networkService.requestData(
        //     endpoint: "/api/v1/chat/clear",
        //     method: "DELETE",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}
