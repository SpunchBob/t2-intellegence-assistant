//
//  CoinService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

@MainActor
class CoinService {
    static let shared = CoinService()
    
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // Загрузка баланса койнов с сервера
    func loadBalance() async throws -> Coin {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<Coin>(endpoint: "/api/v1/coins/balance")
        
        // Временная заглушка
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // В реальном приложении:
        // let response: CoinResponse = try await networkService.request(
        //     endpoint: "/api/v1/coins/balance",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        // return response.coin
        
        return Coin(amount: 1250)
    }
    
    // Добавление койнов
    func addCoins(_ amount: Int) async throws -> Coin {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<Coin>(
        //     endpoint: "/api/v1/coins/add",
        //     method: "POST",
        //     body: ["amount": amount],
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 300_000_000)
        return Coin(amount: 1250 + amount)
    }
    
    // Списание койнов
    func spendCoins(_ amount: Int) async throws -> Coin {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<Coin>(
        //     endpoint: "/api/v1/coins/spend",
        //     method: "POST",
        //     body: ["amount": amount],
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 300_000_000)
        return Coin(amount: 1250 - amount)
    }
    
    // История транзакций
    func loadTransactionHistory() async throws -> [CoinTransaction] {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<[CoinTransaction]>(
        //     endpoint: "/api/v1/coins/transactions",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
}

// Модель для истории транзакций
struct CoinTransaction: Identifiable, Codable {
    let id: UUID
    let amount: Int
    let type: TransactionType
    let description: String
    let timestamp: Date
    
    enum TransactionType: String, Codable {
        case earned
        case spent
        case bonus
    }
}
