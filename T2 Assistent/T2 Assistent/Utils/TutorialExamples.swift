//
//  TutorialExamples.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import SwiftUI

/// Примеры конфигураций туториалов
extension TutorialConfig {
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
        overlayColor: Color.black.opacity(0.7),
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
                description: "Добро пожаловать в T2 Интеллектуальный помощник!",
                targetViewId: nil,
                position: .center
            )
        ],
        overlayColor: Color.black.opacity(0.7),
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
                description: "Добро пожаловать в T2 Интеллектуальный помощник!",
                targetViewId: "123",
                position: .center
            )
        ],
        overlayColor: Color.black.opacity(0.7),
        highlightColor: Color.tele2Pink.opacity(0.3),
        cornerRadius: 16,
        padding: 8
    )
}

/// Пример использования системы туториалов
/*
 
 // В любом View можно запустить туториал:
 
 Button("Показать туториал") {
     TutorialManager.shared.startTutorial(.shopTutorial)
 }
 
 // Для добавления поддержки туториалов к View (автоматическое определение размеров):
 
 myView
     .withTutorialSupport(viewId: "uniqueViewId")
 
 // С явным указанием размера и позиции:
 
 myView
     .withTutorialSupport(
         viewId: "uniqueViewId",
         size: CGSize(width: 200, height: 100),
         position: CGPoint(x: 100, y: 200)
     )
 
 // С явным указанием полного фрейма:
 
 myView
     .withTutorialSupport(
         viewId: "uniqueViewId",
         frame: CGRect(x: 0, y: 0, width: 200, height: 100)
     )
 
 // С использованием TutorialViewParams:
 
 myView
     .withTutorialSupport(
         viewId: "uniqueViewId",
         params: TutorialViewParams(
             size: CGSize(width: 200, height: 100),
             position: CGPoint(x: 100, y: 200)
         )
     )
 
 // Пример для View в ScrollView с динамическим обновлением:
 
 struct ScrollableView: View {
     @State private var viewFrame: CGRect = .zero
     
     var body: some View {
         ScrollView {
             VStack {
                 myView
                     .readFrame(into: $viewFrame)
                     .withTutorialSupport(
                         viewId: "myView",
                         frame: viewFrame
                     )
             }
         }
     }
 }
 
 // Пример с явным указанием размера и позиции:
 
 struct CustomPositionView: View {
     var body: some View {
         myView
             .withTutorialSupport(
                 viewId: "myView",
                 size: CGSize(width: 200, height: 100),
                 position: CGPoint(x: UIScreen.main.bounds.width / 2, y: 200)
             )
     }
 }
 
 // Пример с использованием binding для динамического обновления:
 
 struct DynamicTutorialView: View {
     @State private var viewFrame: CGRect = .zero
     
     var body: some View {
         myView
             .readFrame(into: $viewFrame)
             .withTutorialSupport(
                 viewId: "myView",
                 frame: viewFrame
             )
             .onChange(of: viewFrame) { newFrame in
                 // Автоматически обновляется при изменении фрейма
                 if newFrame != .zero {
                     TutorialManager.shared.updateHighlightedViewFrame(newFrame, for: "myView")
                 }
             }
     }
 }
 
 */
