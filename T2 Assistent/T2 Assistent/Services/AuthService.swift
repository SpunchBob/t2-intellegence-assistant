//
//  AuthService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import Foundation

@MainActor
class AuthService {
    static let shared = AuthService()
    
    private let networkService = NetworkService.shared
    private let userIdKey = "T2_USER_ID"
    
    private(set) var currentUserId: Int?
    private(set) var isNewUser: Bool = false
    
    private init() {
        // Загружаем сохраненный userId при инициализации
        if let savedUserId = UserDefaults.standard.object(forKey: userIdKey) as? Int {
            self.currentUserId = savedUserId
        }
    }
    
    /// Авторизация пользователя. Создает нового пользователя если его нет.
    /// - Parameter userId: ID пользователя (положительное целое число)
    /// - Returns: LoginResponse с информацией о пользователе
    func login(userId: Int) async throws -> LoginResponse {
        guard userId > 0 else {
            throw NetworkError.insufficientBalance // Invalid userId
        }
        
        let response: LoginResponse = try await networkService.request(
            endpoint: "/api/Auth/login",
            method: "POST",
            body: ["id": userId]
        )
        
        // Сохраняем userId локально
        self.currentUserId = response.userId
        self.isNewUser = response.isNewUser
        UserDefaults.standard.set(response.userId, forKey: userIdKey)
        
        return response
    }
    
    /// Проверяет, авторизован ли пользователь
    var isLoggedIn: Bool {
        return currentUserId != nil
    }
    
    /// Генерирует случайный userId для нового пользователя
    func generateUserId() -> Int {
        return Int.random(in: 10000...99999999)
    }
    
    /// Автоматическая авторизация - если нет userId, создает нового пользователя
    func autoLogin() async throws -> LoginResponse {
        let userId = currentUserId ?? generateUserId()
        return try await login(userId: userId)
    }
    
    /// Выход из аккаунта (удаляет локальные данные)
    func logout() {
        currentUserId = nil
        isNewUser = false
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }
}
