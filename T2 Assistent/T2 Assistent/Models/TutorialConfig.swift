//
//  TutorialConfig.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import SwiftUI

/// Конфигурация туториала
struct TutorialConfig {
    let steps: [TutorialStep]
    let overlayColor: Color
    let highlightColor: Color
    let cornerRadius: CGFloat
    let padding: CGFloat
    
    /// Пример туториала для магазина
    static let shopTutorial = TutorialConfig(
        steps: [
            TutorialStep(
                id: "myPet",
                title: "Мой Питомец",
                description: "Здесь вы можете кастомизировать своего питомца Макса.",
                targetViewId: "myPetCard",
                position: .bottom
            )
        ],
        overlayColor: Color.black.opacity(0.8),
        highlightColor: Color.tele2Pink.opacity(0.3),
        cornerRadius: 16,
        padding: 8
    )
    
    /// Пример туториала для главного экрана
    static let mainTutorial = TutorialConfig(
        steps: [
            TutorialStep(
                id: "welcome",
                title: "Привет!",
                description: "Добро пожаловать в T2 Интеллектуальный помощник!fklasjdfklasdjklfadsjkfhasjdkfhajksldfhjalksfhjlkdsfhjlasdhfjksdhflkjashjkfsahdljfagshjlgfashjldfghsadjfklsadghjksdfhgk",
                targetViewId: nil,
                position: .center
            )
        ],
        overlayColor: Color.black.opacity(0.8),
        highlightColor: Color.tele2Pink.opacity(0.3),
        cornerRadius: 16,
        padding: 8
    )
    
    /// Пример туториала для главного экрана
    static let coins = TutorialConfig(
        steps: [
            TutorialStep(
                id: "1223",
                title: "Привет!",
                description: "Добро пожаловДобро пожаловать в T2 Интеллектуальный помощник!fklasjdfklasdjklfadsjkfhasjdkfhajksldfhjalksfhjlkdsfhjlasdhfjksdhflkjashjkfsahdljfagshjlgfashjldfghsadjfklsadghjksdfhgkДобро пожаловать в T2 Интеллектуальный помощник!fklasjdfklasdjklfadsjkfhasjdkfhajksldfhjalksfhjlkdsfhjlasdhfjksdhflkjashjkfsahdljfagshjlgfashjldfghsadjfklsadghjksdfhgkать в T2 Интеллектуальный помощник!",
                targetViewId: "123",
                position: .center
            )
        ],
        overlayColor: Color.black.opacity(0.8),
        highlightColor: Color.tele2Pink.opacity(0.3),
        cornerRadius: 16,
        padding: 8
    )
}
