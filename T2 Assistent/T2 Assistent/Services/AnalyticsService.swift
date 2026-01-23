//
//  AnalyticsService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import Foundation
import Combine

/// Сервис для отправки аналитики действий пользователя через WebSocket
@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    private var isConnected = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    // Уникальный ID устройства/сессии
    private let clientId: String
    
    // Базовый URL сервера (можно вынести в конфигурацию)
    private let serverURL = "http://185.113.139.92:8000"
    
    private init() {
        // Генерируем или получаем сохраненный client_id
        if let savedClientId = UserDefaults.standard.string(forKey: "analytics_client_id") {
            self.clientId = savedClientId
        } else {
            let newClientId = "1"
            UserDefaults.standard.set(newClientId, forKey: "analytics_client_id")
            self.clientId = newClientId
        }
    }
    
    /// Подключение к WebSocket серверу
    func connect() {
        guard !isConnected else { return }
        
        let urlString = "\(serverURL)/ws/analytics/\(clientId)"
        guard let url = URL(string: urlString) else {
            print("AnalyticsService: Invalid URL: \(urlString)")
            return
        }
        
        let request = URLRequest(url: url)
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        
        isConnected = true
        reconnectAttempts = 0
        
        // Начинаем слушать ответы от сервера
        receiveMessage()
        
        print("AnalyticsService: Connected to \(urlString)")
    }
    
    /// Отключение от WebSocket сервера
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        print("AnalyticsService: Disconnected")
    }
    
    /// Отправка действия пользователя
    private func logAction(action: String) {
        // Если не подключены, пытаемся подключиться
        if !isConnected {
            connect()
        }
        
        // Формируем сообщение согласно документации
        let message: [String: Any] = [
            "user_id": self.clientId,
            "action": action
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("AnalyticsService: Failed to serialize message")
            return
        }
        
        let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
        
        webSocketTask?.send(wsMessage) { error in
            if let error = error {
                print("AnalyticsService: Error sending message: \(error.localizedDescription)")
                // Пытаемся переподключиться при ошибке
                Task { @MainActor in
                    self.handleConnectionError()
                }
            } else {
                print("AnalyticsService: Action logged - user_id: \(self.clientId), action: \(action)")
            }
        }
    }
    
    /// Получение сообщений от сервера
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleServerMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleServerMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // Продолжаем слушать
                self.receiveMessage()
                
            case .failure(let error):
                print("AnalyticsService: Error receiving message: \(error.localizedDescription)")
                Task { @MainActor in
                    self.handleConnectionError()
                }
            }
        }
    }
    
    /// Обработка сообщения от сервера
    private func handleServerMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("AnalyticsService: Failed to parse server message")
            return
        }
        
        if let status = json["status"] as? String {
            if status == "error" {
                let message = json["message"] as? String ?? "Unknown error"
                print("AnalyticsService: Server error: \(message)")
            } else if status == "success" {
                let message = json["message"] as? String ?? "Success"
                let timestamp = json["timestamp"] as? String ?? ""
                print("AnalyticsService: Server response - \(message), timestamp: \(timestamp)")
            }
        }
    }
    
    /// Обработка ошибки соединения
    private func handleConnectionError() {
        isConnected = false
        
        guard reconnectAttempts < maxReconnectAttempts else {
            print("AnalyticsService: Max reconnect attempts reached")
            return
        }
        
        reconnectAttempts += 1
        let delay = min(Double(reconnectAttempts) * 2.0, 30.0) // Экспоненциальная задержка, макс 30 сек
        
        print("AnalyticsService: Attempting to reconnect in \(delay) seconds (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            self.connect()
        }
    }
    
    /// Получение client_id (для отладки)
    func getClientId() -> String {
        return clientId
    }
    
    func log(_ type: UserActionType) {
        logAction(action: type.rawValue)
    }
}
