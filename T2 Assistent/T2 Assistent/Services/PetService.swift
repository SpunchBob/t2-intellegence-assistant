//
//  PetService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

@MainActor
class PetService {
    static let shared = PetService()
    
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // Загрузка данных питомца с сервера
    func loadPet() async throws -> Pet {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<Pet>(endpoint: "/api/v1/pet")
        
        // Временная заглушка для демонстрации
        try await Task.sleep(nanoseconds: 500_000_000) // Имитация задержки сети
        
        // В реальном приложении здесь будет:
        // let response: PetResponse = try await networkService.request(
        //     endpoint: "/api/v1/pet",
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        // return response.pet
        
        return Pet(name: "Макс", level: 1, experience: 0)
    }
    
    // Обновление данных питомца на сервере
    func updatePet(_ pet: Pet) async throws -> Pet {
        // TODO: Замените на реальный endpoint
        // let body = [
        //     "name": pet.name,
        //     "level": pet.level,
        //     "experience": pet.experience
        // ]
        // return try await networkService.request<Pet>(
        //     endpoint: "/api/v1/pet",
        //     method: "PUT",
        //     body: body,
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 300_000_000)
        return pet
    }
    
    // Добавление опыта питомцу
    func addExperience(_ amount: Int) async throws -> Pet {
        // TODO: Замените на реальный endpoint
        // return try await networkService.request<Pet>(
        //     endpoint: "/api/v1/pet/experience",
        //     method: "POST",
        //     body: ["amount": amount],
        //     headers: ["Authorization": "Bearer \(token)"]
        // )
        
        try await Task.sleep(nanoseconds: 300_000_000)
        return Pet(name: "Макс", level: 1, experience: amount)
    }
}
