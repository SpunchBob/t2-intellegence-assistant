//
//  APIModels.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import Foundation

// MARK: - Auth API Models

struct LoginRequest: Codable {
    let id: Int
}

struct LoginResponse: Codable {
    let userId: Int
    let isNewUser: Bool
    let message: String
}

// MARK: - Balance API Models

struct BalanceResponse: Codable {
    let amount: Double
}

struct BalanceUpdateRequest: Codable {
    let amount: Double
}

// MARK: - Product API Models

struct ProductsResponse: Codable {
    let products: [APIProduct]
    let bestCategory: String
    let sale: Int
}

struct APIProduct: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let price: Double
    let category: String
    let isDiscounted: Bool
    let discountedPrice: Double?
    
    // Конвертация в локальную модель ShopItem
    func toShopItem() -> ShopItem {
        let shopCategory: ShopCategory
        switch category.lowercased() {
        case "gb":
            shopCategory = .gb
        case "min":
            shopCategory = .min
        case "msg":
            shopCategory = .msg
        default:
            shopCategory = .all
        }
        
        return ShopItem(
            id: UUID(),
            name: name,
            description: description,
            price: Int(discountedPrice ?? price),
            originalPrice: isDiscounted ? Int(price) : nil,
            iconName: getIconName(for: category),
            isPurchased: false,
            category: shopCategory,
            isRecommended: isDiscounted,
            isDealOfTheDay: false,
            productId: id
        )
    }
    
    private func getIconName(for category: String) -> String {
        switch category.lowercased() {
        case "gb":
            return "antenna.radiowaves.left.and.right"
        case "minutes":
            return "phone.fill"
        case "discounts":
            return "tag.fill"
        default:
            return "gift.fill"
        }
    }
}

// MARK: - Purchase API Models

struct PurchaseRequest: Codable {
    let userId: Int
    let productId: Int
    let purchasePrice: Double
    let purchasedAt: String?
}

struct PurchaseResponse: Codable {
    let message: String
    let newBalance: Double
    let purchaseId: Int
}

// MARK: - Task API Models

struct APITask: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let reward: Double
    let isCompleted: Bool
    
    // Конвертация в локальную модель Quest
    func toQuest() -> Quest {
        return Quest(
            id: UUID(),
            title: name,
            description: description,
            reward: Int(reward),
            isCompleted: isCompleted,
            progress: isCompleted ? 1 : 0,
            maxProgress: 1,
            taskId: id
        )
    }
}

struct TaskCompleteRequest: Codable {
    let userId: Int
    let taskId: Int
}
