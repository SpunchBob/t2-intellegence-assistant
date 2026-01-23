//
//  Pet.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

struct Pet: Identifiable, Codable {
    let id: Int
    var type: String
    var location: String
    var crown: String
    
    init(id: Int = 0, type: String = "dragon", location: String = "home", crown: String = "hat") {
        self.id = id
        self.type = type
        self.location = location
        self.crown = crown
    }
    
    /// Возвращает имя изображения для питомца на основе типа и короны
    var iconName: String {
        let typeName = type.capitalized
        let crownName = crown.isEmpty || crown == "none" ? "Classic" : "Crown"
        return "\(typeName)\(crownName)"
    }
}

/// Запрос на обновление питомца
struct PetUpdateRequest: Encodable {
    let id: Int
    let type: String
    let location: String
    let crown: String
    
    init(from pet: Pet) {
        self.id = pet.id
        self.type = pet.type
        self.location = pet.location
        self.crown = pet.crown
    }
}
