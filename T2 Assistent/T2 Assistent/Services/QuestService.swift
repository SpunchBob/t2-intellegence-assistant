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
    
    private init() {}
    
    // Загрузка ежедневных квестов
    func loadDailyQuests() async throws -> [Quest] {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<[Quest]>(
        //     endpoint: "/api/v1/quests/daily",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Временные данные
        return [
            Quest(
                title: "Зайти в приложение",
                description: "",
                reward: 10,
                isCompleted: true,
                progress: 1,
                maxProgress: 1
            ),
            Quest(
                title: "Проверить баланс",
                description: "",
                reward: 10,
                isCompleted: true,
                progress: 1,
                maxProgress: 1
            ),
            Quest(
                title: "Использовать помощника",
                description: "",
                reward: 20,
                isCompleted: false,
                progress: 0,
                maxProgress: 1
            ),
            Quest(
                title: "Купить что-то в магазине",
                description: "",
                reward: 50,
                isCompleted: false,
                progress: 0,
                maxProgress: 1
            ),
            Quest(
                title: "Сыграть в одну игру",
                description: "",
                reward: 30,
                isCompleted: false,
                progress: 0,
                maxProgress: 1
            )
        ]
    }
    
    // Загрузка всех квестов (ежедневные + недельные + специальные)
    func loadAllQuests() async throws -> [Quest] {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<[Quest]>(
        //     endpoint: "/api/v1/quests",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 600_000_000)
        return try await loadDailyQuests()
    }
    
    // Отметка квеста как выполненного
    func completeQuest(_ questId: UUID) async throws -> QuestCompletionResult {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<QuestCompletionResult>(
        //     endpoint: "/api/v1/quests/\(questId.uuidString)/complete",
        //     method: "POST",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 400_000_000)
        return QuestCompletionResult(
            success: true,
            reward: 10,
            message: "Квест выполнен", newBalance: nil
        )
    }
    
    // Обновление прогресса квеста
    func updateQuestProgress(_ questId: UUID, progress: Int) async throws -> Quest {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<Quest>(
        //     endpoint: "/api/v1/quests/\(questId.uuidString)/progress",
        //     method: "PUT",
        //     body: ["progress": progress],
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 300_000_000)
        return Quest(
            title: "Квест",
            description: "",
            reward: 10,
            progress: progress,
            maxProgress: 100
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
