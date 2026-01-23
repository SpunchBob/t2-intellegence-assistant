//
//  AccountService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import Foundation

@MainActor
class AccountService {
    static let shared = AccountService()
    
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // Загрузка данных аккаунта
    func loadAccount() async throws -> Account {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<Account>(endpoint: "/api/v1/account")
        
        // Временная заглушка
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return Account(
            phoneNumber: "+7 904 216 51 49",
            balance: 134.95,
            isBlocked: true,
            requiredTopUp: 761.0
        )
    }
    
    // Обновление баланса
    func updateBalance(_ newBalance: Double) async throws -> Account {
        // TODO: Замените на реальный endpoint
        try await Task.sleep(nanoseconds: 300_000_000)
        
        return Account(
            phoneNumber: "+7 904 216 51 49",
            balance: newBalance,
            isBlocked: newBalance >= 895.95, // Разблокировка при пополнении
            requiredTopUp: nil
        )
    }
    
    // Получение доступных сумм пополнения
    func getTopUpAmounts() async throws -> [TopUpAmount] {
        // TODO: Замените на реальный endpoint
        try await Task.sleep(nanoseconds: 200_000_000)
        
        return [
            TopUpAmount(amount: 100, isRecommended: false),
            TopUpAmount(amount: 300, isRecommended: false),
            TopUpAmount(amount: 500, isRecommended: false),
            TopUpAmount(amount: 761, bonus: 0, isRecommended: true),
            TopUpAmount(amount: 1000, bonus: 50, isRecommended: false),
            TopUpAmount(amount: 2000, bonus: 200, isRecommended: false)
        ]
    }
    
    // Получение способов оплаты
    func getPaymentMethods() async throws -> [PaymentMethod] {
        // TODO: Замените на реальный endpoint
        try await Task.sleep(nanoseconds: 200_000_000)
        
        return [
            PaymentMethod(
                name: "Банковская карта",
                iconName: "creditcard.fill",
                description: "Visa, Mastercard, МИР"
            ),
            PaymentMethod(
                name: "СБП",
                iconName: "arrow.left.arrow.right.circle.fill",
                description: "Быстрый платеж"
            ),
            PaymentMethod(
                name: "Электронные кошельки",
                iconName: "wallet.pass.fill",
                description: "ЮMoney, QIWI"
            ),
            PaymentMethod(
                name: "С баланса телефона",
                iconName: "phone.fill",
                description: nil
            )
        ]
    }
    
    // Инициирование платежа
    func initiatePayment(amount: Double, method: PaymentMethod) async throws -> PaymentResult {
        // TODO: Замените на реальный endpoint
        try await Task.sleep(nanoseconds: 1000_000_000)
        
        return PaymentResult(
            success: true,
            transactionId: UUID().uuidString,
            message: "Платеж успешно обработан"
        )
    }
}

struct PaymentResult {
    let success: Bool
    let transactionId: String?
    let message: String
}
