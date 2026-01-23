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
    private let authService = AuthService.shared
    
    private init() {}
    
    /// Получить userId для запросов
    private func getUserId() throws -> Int {
        guard let userId = authService.currentUserId else {
            throw NetworkError.notFound
        }
        return userId
    }
    
    /// Получение информации о питомце
    /// GET /api/Pet/getPet/{userId}
    func loadPet() async throws -> Pet {
        let userId = try getUserId()
        
        let pet: Pet = try await networkService.request(
            endpoint: "/api/Pet/getPet/\(userId)"
        )
        
        return pet
    }
    
    /// Обновление данных питомца на сервере
    /// PUT /api/Pet/updatePet/{userId}
    func updatePet(_ pet: Pet) async throws {
        let userId = try getUserId()
        
        let body: [String: Any] = [
            "id": pet.id,
            "type": pet.type,
            "location": pet.location,
            "crown": pet.crown
        ]
        
        try await networkService.requestVoid(
            endpoint: "/api/Pet/updatePet/\(userId)",
            method: "PUT",
            body: body
        )
    }
    
    /// Обновление типа питомца
    func updatePetType(_ pet: Pet, newType: String) async throws -> Pet {
        var updatedPet = pet
        updatedPet.type = newType
        try await updatePet(updatedPet)
        return updatedPet
    }
    
    /// Обновление короны питомца
    func updatePetCrown(_ pet: Pet, newCrown: String) async throws -> Pet {
        var updatedPet = pet
        updatedPet.crown = newCrown
        try await updatePet(updatedPet)
        return updatedPet
    }
    
    /// Обновление локации питомца
    func updatePetLocation(_ pet: Pet, newLocation: String) async throws -> Pet {
        var updatedPet = pet
        updatedPet.location = newLocation
        try await updatePet(updatedPet)
        return updatedPet
    }
}
