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
    private let authService = AuthService.shared
    
    private init() {}
    
    /// Получить userId для запросов
    private func getUserId() throws -> Int {
        guard let userId = authService.currentUserId else {
            throw NetworkError.notFound
        }
        return userId
    }
    
    /// Загрузка баланса с сервера
    /// GET /api/Balance/{userId}
    func loadBalance() async throws -> Coin {
        let userId = try getUserId()
        
        let response: BalanceResponse = try await networkService.request(
            endpoint: "/api/Balance/\(userId)"
        )
        
        return Coin(amount: Int(response.amount))
    }
    
    /// Обновление баланса на сервере (для теста/демо)
    /// PUT /api/Balance/{userId}
    func updateBalance(_ amount: Double) async throws -> Coin {
        let userId = try getUserId()
        
        let _: BalanceResponse = try await networkService.request(
            endpoint: "/api/Balance/\(userId)",
            method: "PUT",
            body: ["amount": amount]
        )
        
        return Coin(amount: Int(amount))
    }
    
    /// Добавление койнов (через обновление баланса)
    func addCoins(_ amount: Int) async throws -> Coin {
        // Сначала получаем текущий баланс
        let currentBalance = try await loadBalance()
        let newAmount = Double(currentBalance.amount + amount)
        
        return try await updateBalance(newAmount)
    }
    
    /// Списание койнов (через обновление баланса)
    func spendCoins(_ amount: Int) async throws -> Coin {
        // Сначала получаем текущий баланс
        let currentBalance = try await loadBalance()
        
        guard currentBalance.amount >= amount else {
            throw NetworkError.insufficientBalance
        }
        
        let newAmount = Double(currentBalance.amount - amount)
        return try await updateBalance(newAmount)
    }
    
    /// История транзакций (заглушка - API не предоставляет)
    func loadTransactionHistory() async throws -> [CoinTransaction] {
        // API не предоставляет историю транзакций
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
