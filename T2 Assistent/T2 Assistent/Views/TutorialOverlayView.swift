//
//  TutorialOverlayView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import SwiftUI

/// Overlay для отображения туториала
struct TutorialOverlayView: View {
    @Environment(UserStateService.self) private var userState
    @ObservedObject var tutorialManager = TutorialManager.shared
    @State private var highlightFrame: CGRect = .zero
    @State private var showPetGuide: Bool = false
    
    var body: some View {
        if shouldShowOverlay,
           let step = tutorialManager.currentStep,
           let tutorial = tutorialManager.currentTutorial {
            
            ZStack {
                // Затемненный фон с вырезом для выделенного объекта
                overlayBackground(highlightFrame: highlightFrame, config: tutorial)
                    .allowsHitTesting(false)
                
                // Питомец + облачко с текстом
                petGuide(step: step)
                    .allowsHitTesting(false)
                
                // Кнопка подтверждения
                okButton
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    showPetGuide = true
                }
            }
            .onChange(of: tutorialManager.currentStepIndex) { _, _ in
                // Легкая «переподача» реплики при смене шага
                showPetGuide = false
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    showPetGuide = true
                }
            }
            .onReceive(tutorialManager.$highlightedViewFrame) { frame in
                if let frame = frame {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        highlightFrame = frame
                    }
                }
            }
        }
    }

    private var shouldShowOverlay: Bool {
        guard tutorialManager.isTutorialActive else { return false }
        if tutorialManager.isPetEscaped {
            return tutorialManager.currentStep?.id == "petEscapeFound"
        }
        return true
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
    
    private func petGuide(step: TutorialStep) -> some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, spacing: 14) {
                    // Питомец
                    PetAvatarView(iconName: userState.pet.iconName, isPetEscaped: tutorialManager.isPetEscaped)
                        .frame(width: 84, height: 84)
                        .accessibilityLabel("Питомец")
                    
                    // Облачко с репликой
                    SpeechBubble(
                        title: step.title,
                        message: step.description
                    )
                    .frame(maxWidth: 320, alignment: .leading)
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, overlayBottomPadding)
                .opacity(showPetGuide ? 1 : 0)
                .scaleEffect(showPetGuide ? 1 : 0.96, anchor: .bottomLeading)
                .offset(y: showPetGuide ? 0 : 10)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    /// Кнопка подтверждения
    private var okButton: some View {
        VStack {
            Spacer()
            
            Button(action: {
                if tutorialManager.currentStepIndex < (tutorialManager.currentTutorial?.steps.count ?? 0) - 1 {
                    tutorialManager.nextStep()
                } else {
                    tutorialManager.finishTutorial()
                }
            }) {
                Text("ОК")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.tele2Pink)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, overlayBottomPadding - 50)
        }
    }

    private var overlayBottomPadding: CGFloat {
        170 // поднимаем окно выше таббара
    }
}

private struct PetAvatarView: View {
    let iconName: String
    let isPetEscaped: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.tele2Pink)
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
            
            if isPetEscaped {
                Image(systemName: "questionmark")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            } else if let uiImage = UIImage(named: iconName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(10)
            } else {
                Image(systemName: iconName)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.orange)
            }
        }
    }
}

private struct SpeechBubble: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 10)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            SpeechBubbleShape(tailSize: CGSize(width: 18, height: 12), tailOffset: 18)
                .fill(Color.tele2DarkSecondary)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 6)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct SpeechBubbleShape: Shape {
    var tailSize: CGSize = CGSize(width: 18, height: 12)
    var tailOffset: CGFloat = 18 // от левого края
    var cornerRadius: CGFloat = 16
    
    func path(in rect: CGRect) -> Path {
        let tailW = max(8, min(tailSize.width, rect.width * 0.25))
        let tailH = max(6, min(tailSize.height, rect.height * 0.25))
        let r = min(cornerRadius, min(rect.width, rect.height) / 2)
        
        // Основной прямоугольник пузыря (с местом под хвост снизу)
        let bubbleRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailH)
        
        var p = Path(roundedRect: bubbleRect, cornerRadius: r)
        
        // Хвост (треугольник) снизу слева
        let baseX = bubbleRect.minX + max(r + 6, min(bubbleRect.width - r - tailW - 6, tailOffset))
        let baseY = bubbleRect.maxY
        
        p.move(to: CGPoint(x: baseX, y: baseY))
        p.addLine(to: CGPoint(x: baseX + tailW * 0.55, y: baseY))
        p.addLine(to: CGPoint(x: baseX + tailW * 0.18, y: baseY + tailH))
        p.closeSubpath()
        
        return p
    }
}
