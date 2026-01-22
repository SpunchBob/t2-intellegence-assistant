//
//  MiniGame.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

struct MiniGame: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var iconName: String
    var maxReward: Int
    var bonusFromMax: Int
    var color: String // Цвет для иконки
    var isAvailable: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        iconName: String,
        maxReward: Int,
        bonusFromMax: Int = 5,
        color: String = "pink",
        isAvailable: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.maxReward = maxReward
        self.bonusFromMax = bonusFromMax
        self.color = color
        self.isAvailable = isAvailable
    }
    
    // Для обратной совместимости
    var reward: Int {
        maxReward
    }
}
