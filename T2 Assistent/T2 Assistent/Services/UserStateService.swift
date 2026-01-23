//
//  UserStateService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

enum LoadingState {
    case idle
    case loading
    case loaded
    case error(String)
}

@Observable
@MainActor
class UserStateService {
    var pet: Pet
    var coin: Coin
    
    // Состояния загрузки
    var authState: LoadingState = .idle
    var balanceState: LoadingState = .idle
    var petState: LoadingState = .idle
    var isInitialized: Bool = false
    
    // Сервисы
    private let authService = AuthService.shared
    private let coinService = CoinService.shared
    private let petService = PetService.shared
    
    // Текущий userId
    var userId: Int? {
        authService.currentUserId
    }
    
    var isNewUser: Bool {
        authService.isNewUser
    }
    
    init() {
        // Инициализация с начальными значениями
        self.pet = Pet()
        self.coin = Coin(amount: 0)
    }
    
    /// Инициализация приложения - авторизация и загрузка данных
    func initialize() async {
        guard !isInitialized else { return }
        
        do {
            // 1. Авторизация
            authState = .loading
            _ = try await authService.autoLogin()
            authState = .loaded
            
            // 2. Загрузка баланса и питомца параллельно
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadBalance() }
                group.addTask { await self.loadPet() }
            }
            
            isInitialized = true
        } catch {
            authState = .error(error.localizedDescription)
            print("Ошибка инициализации: \(error)")
        }
    }
    
    /// Загрузка баланса с сервера
    func loadBalance() async {
        balanceState = .loading
        
        do {
            let loadedCoin = try await coinService.loadBalance()
            self.coin = loadedCoin
            balanceState = .loaded
        } catch {
            balanceState = .error(error.localizedDescription)
            print("Ошибка загрузки баланса: \(error)")
        }
    }
    
    /// Загрузка питомца с сервера
    func loadPet() async {
        petState = .loading
        
        do {
            let loadedPet = try await petService.loadPet()
            self.pet = loadedPet
            petState = .loaded
        } catch {
            petState = .error(error.localizedDescription)
            print("Ошибка загрузки питомца: \(error)")
        }
    }
    
    /// Обновление питомца
    func updatePet(_ pet: Pet) async {
        do {
            try await petService.updatePet(pet)
            self.pet = pet
        } catch {
            print("Ошибка обновления питомца: \(error)")
        }
    }
    
    /// Обновление типа питомца
    func updatePetType(_ newType: String) async {
        do {
            let updatedPet = try await petService.updatePetType(pet, newType: newType)
            self.pet = updatedPet
        } catch {
            print("Ошибка обновления типа питомца: \(error)")
        }
    }
    
    /// Обновление короны питомца
    func updatePetCrown(_ newCrown: String) async {
        do {
            let updatedPet = try await petService.updatePetCrown(pet, newCrown: newCrown)
            self.pet = updatedPet
        } catch {
            print("Ошибка обновления короны питомца: \(error)")
        }
    }
    
    /// Обновление локации питомца
    func updatePetLocation(_ newLocation: String) async {
        do {
            let updatedPet = try await petService.updatePetLocation(pet, newLocation: newLocation)
            self.pet = updatedPet
        } catch {
            print("Ошибка обновления локации питомца: \(error)")
        }
    }
    
    /// Добавление монет (через API)
    func addCoins(_ amount: Int) async {
        do {
            let newCoin = try await coinService.addCoins(amount)
            self.coin = newCoin
        } catch {
            print("Ошибка добавления монет: \(error)")
        }
    }
    
    /// Списание монет (через API)
    func spendCoins(_ amount: Int) async -> Bool {
        guard coin.amount >= amount else { return false }
        
        do {
            let newCoin = try await coinService.spendCoins(amount)
            self.coin = newCoin
            return true
        } catch {
            print("Ошибка списания монет: \(error)")
            return false
        }
    }
    
    /// Синхронное добавление монет (для локального обновления UI)
    func addCoinsLocally(_ amount: Int) {
        coin.amount += amount
    }
    
    /// Синхронное списание монет (для локального обновления UI)
    func spendCoinsLocally(_ amount: Int) -> Bool {
        guard coin.amount >= amount else { return false }
        coin.amount -= amount
        return true
    }
    
    /// Обновление баланса из результата покупки
    func updateBalance(_ newBalance: Int) {
        coin.amount = newBalance
    }
    
    /// Выход из аккаунта
    func logout() {
        authService.logout()
        isInitialized = false
        authState = .idle
        balanceState = .idle
        petState = .idle
        coin = Coin(amount: 0)
        pet = Pet()
    }
}
