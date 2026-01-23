//
//  UserStateService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

@Observable
@MainActor
class UserStateService {
    var pet: Pet
    var coin: Coin
    
    init() {
        // Инициализация с начальными значениями
        self.pet = Pet(name: "Макс", level: 1, experience: 0)
        self.coin = Coin(amount: 1250)
    }
    
    func addCoins(_ amount: Int) {
        coin.amount += amount
    }
    
    func spendCoins(_ amount: Int) -> Bool {
        guard coin.amount >= amount else { return false }
        coin.amount -= amount
        return true
    }
    
    func addExperience(_ amount: Int) {
        pet.experience += amount
        // Проверка на повышение уровня (каждые 100 опыта = новый уровень)
        let newLevel = (pet.experience / 100) + 1
        if newLevel > pet.level {
            pet.level = newLevel
        }
    }
}
