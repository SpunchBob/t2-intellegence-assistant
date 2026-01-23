//
//  TutorialOverlayView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import SwiftUI

/// Overlay для отображения туториала
struct TutorialOverlayView: View {
    @ObservedObject var tutorialManager = TutorialManager.shared
    @State private var highlightFrame: CGRect = .zero
    
    var body: some View {
        if tutorialManager.isTutorialActive,
           let step = tutorialManager.currentStep,
           let tutorial = tutorialManager.currentTutorial {
            
            ZStack {
                // Затемненный фон с вырезом для выделенного объекта
                overlayBackground(highlightFrame: highlightFrame, config: tutorial)
                
                // Текст туториала
                tutorialText(step: step, highlightFrame: highlightFrame)
                
                // Кнопки навигации
                navigationButtons
            }
            .ignoresSafeArea()
            .onReceive(tutorialManager.$highlightedViewFrame) { frame in
                if let frame = frame {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        highlightFrame = frame
                    }
                }
            }
        }
    }
    
    /// Затемненный фон с вырезом для выделенного объекта
    private func overlayBackground(highlightFrame: CGRect, config: TutorialConfig) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Затемненный фон с маской для выреза
                if highlightFrame != .zero {
                    let padding = config.padding
                    let adjustedFrame = CGRect(
                        x: highlightFrame.minX - padding,
                        y: highlightFrame.minY - padding,
                        width: highlightFrame.width + padding * 2,
                        height: highlightFrame.height + padding * 2
                    )
                    
                    // Создаем затемненный фон с вырезом используя compositingGroup
                    ZStack {
                        // Затемненный фон на весь экран
                        config.overlayColor
                            .ignoresSafeArea()
                        
                        // Вырез - белая область (будет вычтена)
                        RoundedRectangle(cornerRadius: config.cornerRadius)
                            .fill(Color.white)
                            .frame(width: adjustedFrame.width, height: adjustedFrame.height)
                            .position(
                                x: adjustedFrame.midX,
                                y: adjustedFrame.midY
                            )
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                    
                    // Подсветка выделенного объекта (граница)
                    RoundedRectangle(cornerRadius: config.cornerRadius)
                        .stroke(config.highlightColor, lineWidth: 3)
                        .frame(width: adjustedFrame.width, height: adjustedFrame.height)
                        .position(
                            x: adjustedFrame.midX,
                            y: adjustedFrame.midY
                        )
                } else {
                    // Если нет выделенного объекта, просто затемненный фон
                    config.overlayColor
                        .ignoresSafeArea()
                }
            }
        }
    }
    
    /// Текст туториала
    private func tutorialText(step: TutorialStep, highlightFrame: CGRect) -> some View {
        GeometryReader { geometry in
            ZStack {
                if highlightFrame != .zero {
                    // Позиционируем текст относительно выделенного объекта
                    let cardPosition = positionForCard(
                        step: step,
                        highlightFrame: highlightFrame,
                        screenSize: geometry.size
                    )
                    
                    tutorialCard(step: step)
                        .position(x: cardPosition.x, y: cardPosition.y)
                } else {
                    // Если нет выделенного объекта, показываем по центру
                    tutorialCard(step: step)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
    }
    
    /// Вычисляет позицию карточки туториала
    private func positionForCard(
        step: TutorialStep,
        highlightFrame: CGRect,
        screenSize: CGSize
    ) -> CGPoint {
        let cardHeight: CGFloat = 150 // Примерная высота карточки
        let cardWidth: CGFloat = 320
        let spacing: CGFloat = 20
        
        switch step.position {
        case .top:
            return CGPoint(
                x: highlightFrame.midX,
                y: max(cardHeight / 2 + spacing, highlightFrame.minY - spacing - cardHeight / 2)
            )
            
        case .bottom:
            return CGPoint(
                x: highlightFrame.midX,
                y: min(screenSize.height - cardHeight / 2 - spacing, highlightFrame.maxY + spacing + cardHeight / 2)
            )
            
        case .left:
            return CGPoint(
                x: max(cardWidth / 2 + spacing, highlightFrame.minX - spacing - cardWidth / 2),
                y: highlightFrame.midY
            )
            
        case .right:
            return CGPoint(
                x: min(screenSize.width - cardWidth / 2 - spacing, highlightFrame.maxX + spacing + cardWidth / 2),
                y: highlightFrame.midY
            )
            
        case .center:
            return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        }
    }
    
    /// Карточка с текстом туториала
    private func tutorialCard(step: TutorialStep) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок
            Text(step.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            // Описание
            Text(step.description)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.tele2DarkSecondary)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .frame(maxWidth: 320)
    }
    
    /// Кнопки навигации
    private var navigationButtons: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                // Кнопка "Пропустить"
                Button(action: {
                    tutorialManager.skipTutorial()
                }) {
                    Text("Пропустить")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                
                Spacer()
                
                // Кнопка "Назад"
                if tutorialManager.currentStepIndex > 0 {
                    Button(action: {
                        tutorialManager.previousStep()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.tele2DarkSecondary)
                        .cornerRadius(12)
                    }
                }
                
                // Кнопка "Далее" / "Готово"
                Button(action: {
                    if tutorialManager.currentStepIndex < (tutorialManager.currentTutorial?.steps.count ?? 0) - 1 {
                        tutorialManager.nextStep()
                    } else {
                        tutorialManager.finishTutorial()
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(tutorialManager.currentStepIndex < (tutorialManager.currentTutorial?.steps.count ?? 0) - 1 ? "Далее" : "Готово")
                        if tutorialManager.currentStepIndex < (tutorialManager.currentTutorial?.steps.count ?? 0) - 1 {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.tele2Pink)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}
