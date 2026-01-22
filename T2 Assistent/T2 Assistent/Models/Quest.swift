//
//  Quest.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

struct Quest: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var reward: Int
    var isCompleted: Bool
    var progress: Int
    var maxProgress: Int
    
    init(id: UUID = UUID(), title: String, description: String, reward: Int, isCompleted: Bool = false, progress: Int = 0, maxProgress: Int = 100) {
        self.id = id
        self.title = title
        self.description = description
        self.reward = reward
        self.isCompleted = isCompleted
        self.progress = progress
        self.maxProgress = maxProgress
    }
}
