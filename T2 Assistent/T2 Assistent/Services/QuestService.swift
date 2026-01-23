//
//  QuestService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

@MainActor
class QuestService {
    static let shared = QuestService()
    
    private let networkService = NetworkService.shared
    private let authService = AuthService.shared
    
    private init() {}
    
    /// Получить userId для запросов
    private func getUserId() throws -> Int {
        guard let userId = authService.currentUserId else {
            throw NetworkError.notFound
        }
        return userId
    }
    
    /// Загрузка невыполненных заданий
    /// GET /api/Task/getTasks/{userId}
    func loadDailyQuests() async throws -> [Quest] {
        let userId = try getUserId()
        
        let tasks: [APITask] = try await networkService.request(
            endpoint: "/api/Task/getTasks/\(userId)"
        )
        
        // Конвертируем API задания в локальные Quest
        return tasks.map { $0.toQuest() }
    }
    
    /// Загрузка всех квестов
    func loadAllQuests() async throws -> [Quest] {
        return try await loadDailyQuests()
    }
    
    /// Отметка квеста как выполненного + начисление награды
    /// POST /api/Task/complete
    func completeQuest(_ quest: Quest) async throws -> QuestCompletionResult {
        let userId = try getUserId()
        
        guard let taskId = quest.taskId else {
            throw NetworkError.notFound
        }
        
        // API возвращает 200 OK без тела или с простым сообщением
        try await networkService.requestVoid(
            endpoint: "/api/Task/complete",
            method: "POST",
            body: [
                "userId": userId,
                "taskId": taskId
            ]
        )
        
        return QuestCompletionResult(
            success: true,
            reward: quest.reward,
            message: "Task completed, reward added",
            newBalance: nil
        )
    }
    
    /// Отметка квеста как выполненного по UUID (для обратной совместимости)
    func completeQuest(_ questId: UUID) async throws -> QuestCompletionResult {
        // Этот метод оставлен для обратной совместимости
        // В реальности нужно использовать completeQuest(_ quest: Quest)
        throw NetworkError.notFound
    }
    
    /// Обновление прогресса квеста (API не поддерживает, заглушка)
    func updateQuestProgress(_ questId: UUID, progress: Int) async throws -> Quest {
        // API не поддерживает обновление прогресса
        // Задания либо выполнены, либо нет
        return Quest(
            title: "Квест",
            description: "",
            reward: 10,
            progress: progress,
            maxProgress: 1
        )
    }
}

// Результат выполнения квеста
struct QuestCompletionResult: Codable {
    let success: Bool
    let reward: Int
    let message: String
    let newBalance: Int?
}
