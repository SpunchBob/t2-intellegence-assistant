//
//  Account.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import Foundation

struct Account: Identifiable, Codable {
    let id: UUID
    var phoneNumber: String
    var balance: Double
    var isBlocked: Bool
    var tariffName: String?
    var requiredTopUp: Double? // Сумма для разблокировки
    
    init(
        id: UUID = UUID(),
        phoneNumber: String = "+7 904 216 51 49",
        balance: Double = 134.95,
        isBlocked: Bool = true,
        tariffName: String? = nil,
        requiredTopUp: Double? = 761.0
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.balance = balance
        self.isBlocked = isBlocked
        self.tariffName = tariffName
        self.requiredTopUp = requiredTopUp
    }
}

struct PromotionCard: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String?
    let iconName: String?
    let iconColor: String
    let backgroundColor: String
    let borderColor: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        iconName: String? = nil,
        iconColor: String = "pink",
        backgroundColor: String = "pink",
        borderColor: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
    }
}

struct TopUpAmount: Identifiable {
    let id: UUID
    let amount: Double
    let bonus: Double?
    let isRecommended: Bool
    
    init(id: UUID = UUID(), amount: Double, bonus: Double? = nil, isRecommended: Bool = false) {
        self.id = id
        self.amount = amount
        self.bonus = bonus
        self.isRecommended = isRecommended
    }
}

struct PaymentMethod: Identifiable {
    let id: UUID
    let name: String
    let iconName: String
    let description: String?
    let isAvailable: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        description: String? = nil,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.description = description
        self.isAvailable = isAvailable
    }
}
