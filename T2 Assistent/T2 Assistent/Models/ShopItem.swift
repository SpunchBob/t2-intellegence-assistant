//
//  ShopItem.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

struct ShopItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var price: Int
    var originalPrice: Int?
    var iconName: String
    var isPurchased: Bool
    var category: ShopCategory
    var isRecommended: Bool
    var isDealOfTheDay: Bool
    var productId: Int? // ID продукта на сервере
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        price: Int,
        originalPrice: Int? = nil,
        iconName: String,
        isPurchased: Bool = false,
        category: ShopCategory = .all,
        isRecommended: Bool = false,
        isDealOfTheDay: Bool = false,
        productId: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.originalPrice = originalPrice
        self.iconName = iconName
        self.isPurchased = isPurchased
        self.category = category
        self.isRecommended = isRecommended
        self.isDealOfTheDay = isDealOfTheDay
        self.productId = productId
    }
}

enum ShopCategory: String, Codable, CaseIterable {
    case all = "Все"
    case gb = "Гиги"
    case min = "Минуты"
    case msg = "Сообщения"
}
