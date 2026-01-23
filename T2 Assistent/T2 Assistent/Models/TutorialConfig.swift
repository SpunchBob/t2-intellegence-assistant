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


    /// Сценарий "Питомец убежал" через пополнение
    static let petEscapeTutorial = TutorialConfig(
        steps: [
            TutorialStep(
                id: "petEscapeDashboardTopUp",
                title: "Питомец убежал!",
                description: "Следы ведут к пополнению. Идём по маршруту.",
                targetViewId: nil,
                position: .bottom
            ),
            TutorialStep(
                id: "petEscapeTopUpButton",
                title: "Он близко",
                description: "Похоже, он на экране оплаты. Идём дальше.",
                targetViewId: nil,
                position: .bottom
            ),
            TutorialStep(
                id: "petEscapeFound",
                title: "Нашёлся!",
                description: "Спасибо, что нашёл меня! Давай покажу, что здесь есть.",
                targetViewId: "petEscapeFoundBanner",
                position: .bottom
            )
        ],
        overlayColor: Color.black.opacity(0.8),
        highlightColor: Color.tele2Pink.opacity(0.35),
        cornerRadius: 16,
        padding: 8
    )

    /// Сценарий с рассказом о возможностях экрана оплаты
    static let petFoundPaymentTutorial = TutorialConfig(
        steps: [
            TutorialStep(
                id: "paymentIntro",
                title: "Ура ты нашел меня!",
                description: "Спасибо, что нашёл меня. Раз уж мы тут, давай покажу, что тут находится. \n\nЗдесь можешь ввести сумму на которую хочешь пополнить баланс",
                targetViewId: "1",
                position: .bottom
            ),
            TutorialStep(
                id: "paymentMethods",
                title: "Сколько спишется",
                description: "Здесь отображается какая косиссия в процентах будет дополнительно снята в зависимости от выбранной типа оплаты",
                targetViewId: "2",
                position: .bottom
            ),
            TutorialStep(
                id: "paymentPay",
                title: "Итоговая стоимость",
                description: "А тут отображается итоговая стоимость пополнения баланса",
                targetViewId: "3",
                position: .top
            ),
            TutorialStep(
                id: "complete",
                title: "Я домой",
                description: "Вроде тут все!\nЯ убежал обратно домой!",
                targetViewId: "123",
                position: .center
            )
        ],
        overlayColor: Color.black.opacity(0.8),
        highlightColor: Color.tele2Pink.opacity(0.35),
        cornerRadius: 16,
        padding: 8
    )
}
