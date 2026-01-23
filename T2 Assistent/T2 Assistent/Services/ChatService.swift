//
//  ChatService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

// MARK: - GigaChat API Response Models
struct GigaChatResponse: Codable {
    let response: String?
    let message: String?
    let error: String?
    
    // Получаем ответ из любого доступного поля
    var text: String {
        return response ?? message ?? "Не удалось получить ответ"
    }
}

@MainActor
class ChatService {
    static let shared = ChatService()
    
    // MARK: - GigaChat API Configuration
    // Замените YOUR_IP на реальный IP-адрес сервера GigaChat
    private let gigaChatBaseURL = "http://185.113.139.92:7000"
    
    private let systemPrompt = """
    Ты - умный асситент-помощник представленный в виде формы животного существа. \
    Твоя основная задача помогать пользователю разбираться в приложении Т2. \
    Отвечай по доброму и старайся все объяснить.
    """
    
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60 // Увеличенный таймаут для AI запросов
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Загрузка истории сообщений
    func loadMessages(limit: Int = 50, offset: Int = 0) async throws -> [ChatMessage] {
        // Возвращаем пустой массив - история будет храниться локально в ViewModel
        return []
    }
    
    // MARK: - Отправка сообщения пользователя
    func sendMessage(_ text: String) async throws -> ChatMessage {
        return ChatMessage(content: text, isUser: true)
    }
    
    // MARK: - Получение ответа от GigaChat AI
    func getAIResponse(for message: String) async throws -> ChatMessage {
        // Формируем запрос с системным промптом
        let fullMessage = "\(systemPrompt)\n\nВопрос пользователя: \(message)"
        
        // Пробуем получить ответ от GigaChat API
        do {
            let response = try await sendToGigaChat(message: fullMessage)
            return ChatMessage(content: response, isUser: false)
        } catch {
            // В случае ошибки используем fallback
            print("GigaChat API Error: \(error)")
            let fallbackResponse = generateFallbackResponse(for: message)
            return ChatMessage(content: fallbackResponse, isUser: false)
        }
    }
    
    // MARK: - GigaChat API Request (POST)
    private func sendToGigaChat(message: String) async throws -> String {
        guard let url = URL(string: "\(gigaChatBaseURL)/api/chat") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "message": message
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "ChatService", code: -1))
        }
        
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        // Пробуем декодировать как JSON
        if let gigaResponse = try? JSONDecoder().decode(GigaChatResponse.self, from: data) {
            return gigaResponse.text
        }
        
        // Если не удалось декодировать JSON, пробуем как plain text
        if let textResponse = String(data: data, encoding: .utf8) {
            return textResponse
        }
        
        throw NetworkError.decodingError
    }
    
    // MARK: - GigaChat API Simple Request (GET) - альтернативный метод
    func getAIResponseSimple(for message: String) async throws -> ChatMessage {
        let fullMessage = "\(systemPrompt)\n\nВопрос пользователя: \(message)"
        
        guard var components = URLComponents(string: "\(gigaChatBaseURL)/api/v1/chat/simple") else {
            throw NetworkError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "message", value: fullMessage),
            URLQueryItem(name: "system_prompt", value: systemPrompt)
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw NetworkError.serverError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        
        if let gigaResponse = try? JSONDecoder().decode(GigaChatResponse.self, from: data) {
            return ChatMessage(content: gigaResponse.text, isUser: false)
        }
        
        if let textResponse = String(data: data, encoding: .utf8) {
            return ChatMessage(content: textResponse, isUser: false)
        }
        
        throw NetworkError.decodingError
    }
    
    // MARK: - Fallback ответы при недоступности API
    private func generateFallbackResponse(for message: String) -> String {
        let lowercased = message.lowercased()
        
        if lowercased.contains("привет") || lowercased.contains("здравствуй") {
            return "Привет! Рад тебя видеть! Я твой помощник по приложению Т2. Чем могу помочь? 🦊"
        } else if lowercased.contains("тариф") || lowercased.contains("пакет") {
            return "Я могу помочь тебе разобраться с тарифами! В приложении Т2 есть разные пакеты для интернета и звонков. Что тебя интересует?"
        } else if lowercased.contains("баланс") || lowercased.contains("деньги") {
            return "Для проверки баланса загляни на главную страницу приложения - там отображается текущий баланс и остаток пакетов."
        } else if lowercased.contains("монет") || lowercased.contains("coin") {
            return "Монеты - это внутренняя валюта приложения! Ты можешь зарабатывать их, выполняя задания и квесты, а потом тратить в магазине на полезные бонусы."
        } else if lowercased.contains("магазин") || lowercased.contains("shop") {
            return "В магазине ты можешь обменять свои монеты на гигабайты, минуты и другие полезные бонусы! Заходи в раздел 'Магазин'."
        } else if lowercased.contains("квест") || lowercased.contains("задани") {
            return "Квесты - это интересные задания, за выполнение которых ты получаешь монеты! Проверяй новые квесты регулярно."
        } else if lowercased.contains("помощ") || lowercased.contains("help") {
            return "Я здесь, чтобы помочь! Можешь спросить меня о тарифах, балансе, монетах, магазине или любых других функциях приложения Т2."
        } else {
            return "Интересный вопрос! К сожалению, сейчас у меня небольшие проблемы с подключением, но попробуй спросить ещё раз чуть позже. Я обязательно помогу! 🦊"
        }
    }
    
    // MARK: - Отправка голосового сообщения
    func sendVoiceMessage(_ audioData: Data) async throws -> ChatMessage {
        // TODO: Интеграция с speech-to-text и GigaChat
        return ChatMessage(content: "Голосовые сообщения пока в разработке", isUser: false)
    }
    
    // MARK: - Очистка истории чата
    func clearHistory() async throws {
        // История хранится локально в ViewModel
    }
    
    // MARK: - Проверка доступности GigaChat API
    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(gigaChatBaseURL)/health") else {
            return false
        }
        
        do {
            let (_, response) = try await session.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            print("GigaChat health check failed: \(error)")
            return false
        }
    }
}
