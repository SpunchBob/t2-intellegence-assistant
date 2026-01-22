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
    
    private let petService = PetService.shared
    private let coinService = CoinService.shared
    
    var isLoading: Bool = false
    var errorMessage: String?
    
    init() {
        // Инициализация с начальными значениями (будут загружены с сервера)
        self.pet = Pet(name: "Макс", level: 1, experience: 0)
        self.coin = Coin(amount: 1250)
    }
    
    // Загрузка данных с сервера
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Загружаем питомца и койны параллельно
            async let petTask = petService.loadPet()
            async let coinTask = coinService.loadBalance()
            
            let (loadedPet, loadedCoin) = try await (petTask, coinTask)
            
            self.pet = loadedPet
            self.coin = loadedCoin
        } catch {
            errorMessage = "Ошибка загрузки данных: \(error.localizedDescription)"
            print("Error loading data: \(error)")
        }
        
        isLoading = false
    }
    
    func addCoins(_ amount: Int) {
        coin.amount += amount
        
        // Обновляем на сервере асинхронно
        Task {
            do {
                let updatedCoin = try await coinService.addCoins(amount)
                await MainActor.run {
                    self.coin = updatedCoin
                }
            } catch {
                print("Error updating coins on server: \(error)")
            }
        }
    }
    
    func spendCoins(_ amount: Int) -> Bool {
        guard coin.amount >= amount else { return false }
        coin.amount -= amount
        
        // Обновляем на сервере асинхронно
        Task {
            do {
                let updatedCoin = try await coinService.spendCoins(amount)
                await MainActor.run {
                    self.coin = updatedCoin
                }
            } catch {
                print("Error spending coins on server: \(error)")
                // Откатываем изменение при ошибке
                await MainActor.run {
                    self.coin.amount += amount
                }
            }
        }
        
        return true
    }
    
    func addExperience(_ amount: Int) {
        pet.experience += amount
        // Проверка на повышение уровня (каждые 100 опыта = новый уровень)
        let newLevel = (pet.experience / 100) + 1
        if newLevel > pet.level {
            pet.level = newLevel
        }
        
        // Обновляем на сервере асинхронно
        Task {
            do {
                let updatedPet = try await petService.addExperience(amount)
                await MainActor.run {
                    self.pet = updatedPet
                }
            } catch {
                print("Error updating experience on server: \(error)")
            }
        }
    }
    
    func updatePet(_ pet: Pet) async {
        do {
            let updatedPet = try await petService.updatePet(pet)
            self.pet = updatedPet
        } catch {
            errorMessage = "Ошибка обновления питомца: \(error.localizedDescription)"
            print("Error updating pet: \(error)")
        }
    }
}
