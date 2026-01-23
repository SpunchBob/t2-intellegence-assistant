//
//  Pet.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

struct Pet: Identifiable, Codable {
    let id: UUID
    var name: String
    var level: Int
    var experience: Int
    var iconName: String
    
    init(id: UUID = UUID(), name: String = "Питомец", level: Int = 1, experience: Int = 0, iconName: String = "FoxClassic") {
        self.id = id
        self.name = name
        self.level = level
        self.experience = experience
        self.iconName = iconName
    }
}
