//
//  TutorialManager.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import SwiftUI
import Combine

// TODO: - 

/// Менеджер для управления системой туториалов
class TutorialManager: ObservableObject {
    static let shared = TutorialManager()
    
    @Published var currentTutorial: TutorialConfig?
    @Published var currentStepIndex: Int = 0
    @Published var isTutorialActive: Bool = false
    @Published var isPetEscaped: Bool = false
    @Published var highlightedViewFrame: CGRect?
    @Published var highlightedViewId: String?
    @Published var shouldScrollToViewId: String? // Триггер для скролла к элементу
    
    private var cancellables = Set<AnyCancellable>()
    private var hasShownPetEscapeTutorial = false
    private var isPetEscapeTutorialActive = false
    
    private init() {}
    
    /// Начать туториал
    func startTutorial(_ config: TutorialConfig) {
        startTutorial(config, isPetEscape: false)
    }

    /// Начать туториал с флагами сценария
    private func startTutorial(_ config: TutorialConfig, isPetEscape: Bool) {
        guard !config.steps.isEmpty else { return }
        
        isPetEscapeTutorialActive = isPetEscape
        if !isPetEscape {
            isPetEscaped = false
        }
        currentTutorial = config
        currentStepIndex = 0
        isTutorialActive = true
        updateHighlightedView()
    }

    /// Запустить сценарий побега питомца один раз за сессию
    func startPetEscapeTutorialIfNeeded() {
        guard !hasShownPetEscapeTutorial, !isTutorialActive else { return }
        hasShownPetEscapeTutorial = true
        isPetEscapeTutorialActive = true
        isPetEscaped = true
        startTutorial(.petEscapeTutorial, isPetEscape: true)
    }
    
    /// Перейти к следующему шагу
    func nextStep() {
        guard let tutorial = currentTutorial else { return }
        
        if currentStepIndex < tutorial.steps.count - 1 {
            currentStepIndex += 1
            updateHighlightedView()
        } else {
            finishTutorial()
        }
    }
    
    /// Перейти к предыдущему шагу
    func previousStep() {
        guard currentStepIndex > 0 else { return }
        
        currentStepIndex -= 1
        updateHighlightedView()
    }
    
    /// Завершить туториал
    func finishTutorial() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isTutorialActive = false
            highlightedViewFrame = nil
            highlightedViewId = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentTutorial = nil
            self.currentStepIndex = 0
        }

        if isPetEscapeTutorialActive {
            isPetEscaped = false
            isPetEscapeTutorialActive = false
        }
    }
    
    /// Пропустить туториал
    func skipTutorial() {
        finishTutorial()
    }
    
    /// Получить текущий шаг
    var currentStep: TutorialStep? {
        guard let tutorial = currentTutorial,
              currentStepIndex < tutorial.steps.count else {
            return nil
        }
        return tutorial.steps[currentStepIndex]
    }
    
    /// Обновить выделенный View
    private func updateHighlightedView() {
        guard let step = currentStep else { return }
        highlightedViewId = step.targetViewId
        
        // Триггерим скролл к выделяемому элементу
        if let viewId = step.targetViewId {
            // Небольшая задержка для того, чтобы View успел обновиться
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.shouldScrollToViewId = viewId
                // Сбрасываем триггер после небольшой задержки
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if self.shouldScrollToViewId == viewId {
                        self.shouldScrollToViewId = nil
                    }
                }
            }
        }
    }
    
    /// Установить фрейм для выделенного View
    func setHighlightedViewFrame(_ frame: CGRect, for viewId: String) {
        guard highlightedViewId == viewId else { return }
        highlightedViewFrame = frame
    }
    
    /// Обновить фрейм для выделенного View (принудительно)
    func updateHighlightedViewFrame(_ frame: CGRect, for viewId: String) {
        guard highlightedViewId == viewId else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            highlightedViewFrame = frame
        }
    }
    
    /// Установить фрейм используя размер и позицию
    func setHighlightedViewFrame(size: CGSize, position: CGPoint, for viewId: String) {
        guard highlightedViewId == viewId else { return }
        let frame = CGRect(
            x: position.x - size.width / 2,
            y: position.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        highlightedViewFrame = frame
    }
    
    /// Отключить выделение объекта (очистить выделение без завершения туториала)
    func clearHighlight() {
        withAnimation(.easeInOut(duration: 0.2)) {
            highlightedViewFrame = nil
            highlightedViewId = nil
            shouldScrollToViewId = nil
        }
    }
    
    /// Отключить выделение конкретного View по его ID
    func clearHighlight(for viewId: String) {
        guard highlightedViewId == viewId else { return }
        clearHighlight()
    }
}
