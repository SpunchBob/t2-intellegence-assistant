//
//  PetProfileManager.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import SwiftUI

/// Менеджер для управления профилем питомца
@Observable
@MainActor
class PetProfileManager {
    static let shared = PetProfileManager()
    
    /// Показывается ли профиль питомца
    var isPresented: Bool = false
    
    /// Открыть сразу в режиме редактирования
    var startInEditMode: Bool = false
    
    private init() {}
    
    /// Открыть профиль питомца
    func showProfile() {
        startInEditMode = false
        isPresented = true
    }
    
    /// Открыть профиль питомца сразу в режиме редактирования
    func showProfileForEditing() {
        startInEditMode = true
        isPresented = true
    }
    
    /// Закрыть профиль питомца
    func hideProfile() {
        isPresented = false
        startInEditMode = false
    }
}
