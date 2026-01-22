//
//  ShopService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

@MainActor
class ShopService {
    static let shared = ShopService()
    
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // Загрузка всех товаров магазина
    func loadItems(category: ShopCategory? = nil) async throws -> [ShopItem] {
        // TODO: Замените на реальный endpoint
        // var endpoint = "/api/v1/shop/items"
        // if let category = category {
        //     endpoint += "?category=\(category.rawValue)"
        // }
        // return try await networkService.request<[ShopItem]>(
        //     endpoint: endpoint,
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Временные данные для демонстрации
        return [
            ShopItem(
                name: "10 ГБ интернета",
                description: "Дополнительный интернет",
                price: 105,
                originalPrice: 150,
                iconName: "antenna.radiowaves.left.and.right",
                category: .gigs,
                isRecommended: true
            ),
            ShopItem(
                name: "50 ГБ интернета",
                description: "Большой пакет интернета",
                price: 600,
                iconName: "antenna.radiowaves.left.and.right",
                category: .gigs,
                isRecommended: true
            )
        ]
    }
    
    // Загрузка рекомендуемых товаров
    func loadRecommendedItems() async throws -> [ShopItem] {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<[ShopItem]>(
        //     endpoint: "/api/v1/shop/recommended",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 400_000_000)
        return try await loadItems()
    }
    
    // Загрузка акции дня
    func loadDealOfTheDay() async throws -> ShopItem? {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<ShopItem?>(
        //     endpoint: "/api/v1/shop/deal-of-the-day",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 300_000_000)
        return nil
    }
    
    // Покупка товара
    func purchaseItem(_ item: ShopItem) async throws -> PurchaseResult {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<PurchaseResult>(
        //     endpoint: "/api/v1/shop/purchase",
        //     method: "POST",
        //     body: ["item_id": item.id.uuidString],
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 500_000_000)
        return PurchaseResult(success: true, message: "Товар успешно куплен", newBalance: nil)
    }
}

// Результат покупки
struct PurchaseResult: Codable {
    let success: Bool
    let message: String
    let newBalance: Int?
}
