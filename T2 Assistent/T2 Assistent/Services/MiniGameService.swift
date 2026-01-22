//
//  MiniGameService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

@MainActor
class MiniGameService {
    static let shared = MiniGameService()
    
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // Загрузка всех доступных мини-игр
    func loadMiniGames() async throws -> [MiniGame] {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<[MiniGame]>(
        //     endpoint: "/api/v1/mini-games",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Временные данные
        return [
            MiniGame(
                name: "Три в ряд",
                description: "",
                iconName: "grid.circle.fill",
                maxReward: 50,
                bonusFromMax: 5,
                color: "pink"
            ),
            MiniGame(
                name: "BlockBlast",
                description: "",
                iconName: "square.grid.3x3.fill",
                maxReward: 60,
                bonusFromMax: 5,
                color: "orange"
            ),
        ]
    }
    
    // Загрузка конкретной игры
    func loadGame(_ gameId: UUID) async throws -> MiniGame {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<MiniGame>(
        //     endpoint: "/api/v1/mini-games/\(gameId.uuidString)",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 300_000_000)
        return MiniGame(
            name: "Игра",
            description: "",
            iconName: "gamecontroller.fill",
            maxReward: 50,
            bonusFromMax: 5
        )
    }
    
    // Начало игры
    func startGame(_ gameId: UUID) async throws -> GameSession {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<GameSession>(
        //     endpoint: "/api/v1/mini-games/\(gameId.uuidString)/start",
        //     method: "POST",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 400_000_000)
        return GameSession(
            id: UUID(),
            gameId: gameId,
            startedAt: Date()
        )
    }
    
    // Завершение игры и получение награды
    func finishGame(_ sessionId: UUID, score: Int) async throws -> GameResult {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<GameResult>(
        //     endpoint: "/api/v1/mini-games/sessions/\(sessionId.uuidString)/finish",
        //     method: "POST",
        //     body: ["score": score],
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 500_000_000)
        return GameResult(
            success: true,
            reward: 50,
            bonus: 5,
            message: "Игра завершена",
            newBalance: nil
        )
    }
    
    // Получение рекордов игрока
    func loadHighScores(_ gameId: UUID) async throws -> [GameScore] {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<[GameScore]>(
        //     endpoint: "/api/v1/mini-games/\(gameId.uuidString)/scores",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 400_000_000)
        return []
    }
}

// Сессия игры
struct GameSession: Codable {
    let id: UUID
    let gameId: UUID
    let startedAt: Date
}

// Результат игры
struct GameResult: Codable {
    let success: Bool
    let reward: Int
    let bonus: Int
    let message: String
    let newBalance: Int?
}

// Рекорд игры
struct GameScore: Identifiable, Codable {
    let id: UUID
    let gameId: UUID
    let score: Int
    let playerName: String
    let timestamp: Date
}
