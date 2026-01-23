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
    private let authService = AuthService.shared
    
    // Кэш для хранения лучшей категории и скидки
    private(set) var bestCategory: String = ""
    private(set) var salePercent: Int = 0
    
    private init() {}
    
    /// Получить userId для запросов
    private func getUserId() throws -> Int {
        guard let userId = authService.currentUserId else {
            throw NetworkError.notFound
        }
        return userId
    }
    
    /// Загрузка всех товаров магазина с рекомендациями
    /// GET /api/Product/getProducts/{userId}
    func loadItems(category: ShopCategory? = nil) async throws -> [ShopItem] {
        let userId = try getUserId()
        
        let response: ProductsResponse = try await networkService.request(
            endpoint: "/api/Product/getProducts/\(userId)"
        )
        
        // Сохраняем информацию о лучшей категории и скидке
        self.bestCategory = response.bestCategory
        self.salePercent = response.sale
        
        // Конвертируем API продукты в локальные ShopItem
        var items = response.products.map { $0.toShopItem() }
        
        // Фильтруем по категории если нужно
        if let category = category, category != .all {
            items = items.filter { $0.category == category }
        }
        
        return items
    }
    
    /// Загрузка рекомендуемых товаров (товары со скидкой)
    func loadRecommendedItems() async throws -> [ShopItem] {
        let allItems = try await loadItems()
        return allItems.filter { $0.isRecommended }
    }
    
    /// Загрузка акции дня (первый товар со скидкой)
    func loadDealOfTheDay() async throws -> ShopItem? {
        let allItems = try await loadItems()
        return allItems.first { $0.originalPrice != nil }
    }
    
    /// Покупка товара
    /// POST /api/Purchase/makePurchase
    func purchaseItem(_ item: ShopItem) async throws -> PurchaseResult {
        let userId = try getUserId()
        
        guard let productId = item.productId else {
            throw NetworkError.notFound
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let purchasedAt = dateFormatter.string(from: Date())
        
        let response: PurchaseResponse = try await networkService.request(
            endpoint: "/api/Purchase/makePurchase",
            method: "POST",
            body: [
                "userId": userId,
                "productId": productId,
                "purchasePrice": Double(item.price),
                "purchasedAt": purchasedAt
            ]
        )
        
        return PurchaseResult(
            success: true,
            message: response.message,
            newBalance: Int(response.newBalance),
            purchaseId: response.purchaseId
        )
    }
}

// Результат покупки
struct PurchaseResult: Codable {
    let success: Bool
    let message: String
    let newBalance: Int?
    let purchaseId: Int?
    
    init(success: Bool, message: String, newBalance: Int?, purchaseId: Int? = nil) {
        self.success = success
        self.message = message
        self.newBalance = newBalance
        self.purchaseId = purchaseId
    }
}
