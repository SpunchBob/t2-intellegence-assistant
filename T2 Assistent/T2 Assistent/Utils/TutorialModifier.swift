//
//  TutorialModifier.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import SwiftUI

/// Параметры для явного указания размеров и позиции View
public struct TutorialViewParams {
    let size: CGSize?
    let position: CGPoint?
    let frame: CGRect?
    
    /// Создает параметры с явным указанием размера и позиции
    /// - Parameters:
    ///   - size: Размер View
    ///   - position: Позиция центра View в глобальной системе координат
    public init(size: CGSize? = nil, position: CGPoint? = nil) {
        self.size = size
        self.position = position
        if let size = size, let position = position {
            self.frame = CGRect(
                x: position.x - size.width / 2,
                y: position.y - size.height / 2,
                width: size.width,
                height: size.height
            )
        } else {
            self.frame = nil
        }
    }
    
    /// Создает параметры с явным указанием фрейма
    /// - Parameter frame: Полный фрейм View в глобальной системе координат
    public init(frame: CGRect) {
        self.frame = frame
        self.size = frame.size
        self.position = CGPoint(x: frame.midX, y: frame.midY)
    }
}

/// Модификатор для добавления поддержки туториалов к View
struct TutorialViewModifier: ViewModifier {
    let viewId: String
    let explicitParams: TutorialViewParams?
    @ObservedObject private var tutorialManager = TutorialManager.shared
    @State private var viewFrame: CGRect = .zero
    
    init(viewId: String, explicitParams: TutorialViewParams? = nil) {
        self.viewId = viewId
        self.explicitParams = explicitParams
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    // Если явные параметры не указаны, используем GeometryReader для автоматического определения
                    if explicitParams == nil {
                        GeometryReader { geometry in
                            Color.clear
                                .preference(
                                    key: ViewFramePreferenceKey.self,
                                    value: geometry.frame(in: .global)
                                )
                        }
                    } else {
                        // Если параметры указаны явно, все равно отслеживаем изменения через GeometryReader
                        // для возможности динамического обновления
                        GeometryReader { geometry in
                            Color.clear
                                .preference(
                                    key: ViewFramePreferenceKey.self,
                                    value: geometry.frame(in: .global)
                                )
                        }
                    }
                }
            )
            .onPreferenceChange(ViewFramePreferenceKey.self) { frame in
                // Используем явные параметры, если они указаны, иначе автоматически определяем
                if let explicitFrame = explicitParams?.frame {
                    viewFrame = explicitFrame
                } else {
                    viewFrame = frame
                }
                
                // Если этот View должен быть выделен, обновляем фрейм в менеджере
                if tutorialManager.highlightedViewId == viewId {
                    tutorialManager.setHighlightedViewFrame(viewFrame, for: viewId)
                }
            }
            .onChange(of: tutorialManager.highlightedViewId) { newId in
                if newId == viewId {
                    // При изменении выделенного View обновляем фрейм
                    let frameToUse: CGRect
                    if let explicitFrame = explicitParams?.frame {
                        frameToUse = explicitFrame
                    } else {
                        frameToUse = viewFrame
                    }
                    
                    if frameToUse != .zero {
                        tutorialManager.setHighlightedViewFrame(frameToUse, for: viewId)
                    }
                }
            }
            .onAppear {
                // При появлении View, если он должен быть выделен, сразу устанавливаем фрейм
                if tutorialManager.highlightedViewId == viewId {
                    let frameToUse: CGRect
                    if let explicitFrame = explicitParams?.frame {
                        frameToUse = explicitFrame
                    } else if viewFrame != .zero {
                        frameToUse = viewFrame
                    } else {
                        return // Фрейм еще не определен
                    }
                    
                    tutorialManager.setHighlightedViewFrame(frameToUse, for: viewId)
                }
            }
            .id(viewId)
    }
}

/// PreferenceKey для передачи фрейма View наверх
struct ViewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

extension View {
    /// Добавляет поддержку туториалов к View с автоматическим определением размеров и позиции
    /// - Parameter viewId: Уникальный идентификатор View для выделения в туториале
    func withTutorialSupport(viewId: String) -> some View {
        modifier(TutorialViewModifier(viewId: viewId, explicitParams: nil))
    }
    
    /// Добавляет поддержку туториалов к View с явным указанием размеров и позиции
    /// - Parameters:
    ///   - viewId: Уникальный идентификатор View для выделения в туториале
    ///   - params: Параметры с размерами и позицией View
    func withTutorialSupport(viewId: String, params: TutorialViewParams) -> some View {
        modifier(TutorialViewModifier(viewId: viewId, explicitParams: params))
    }
    
    /// Добавляет поддержку туториалов к View с явным указанием фрейма
    /// - Parameters:
    ///   - viewId: Уникальный идентификатор View для выделения в туториале
    ///   - frame: Полный фрейм View в глобальной системе координат
    func withTutorialSupport(viewId: String, frame: CGRect) -> some View {
        modifier(TutorialViewModifier(viewId: viewId, explicitParams: TutorialViewParams(frame: frame)))
    }
    
    /// Добавляет поддержку туториалов к View с явным указанием размера и позиции
    /// - Parameters:
    ///   - viewId: Уникальный идентификатор View для выделения в туториале
    ///   - size: Размер View
    ///   - position: Позиция центра View в глобальной системе координат
    func withTutorialSupport(viewId: String, size: CGSize, position: CGPoint) -> some View {
        modifier(TutorialViewModifier(viewId: viewId, explicitParams: TutorialViewParams(size: size, position: position)))
    }
    
    /// Устаревший метод для обратной совместимости
    func withOverlaySupport() -> some View {
        // Используем случайный ID, если не указан
        modifier(TutorialViewModifier(viewId: UUID().uuidString))
    }
}

/// Хелпер для получения фрейма View и передачи его в модификатор
struct ViewFrameReader: ViewModifier {
    @Binding var frame: CGRect
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ViewFramePreferenceKey.self,
                            value: geometry.frame(in: .global)
                        )
                }
            )
            .onPreferenceChange(ViewFramePreferenceKey.self) { newFrame in
                frame = newFrame
            }
    }
}

extension View {
    /// Читает фрейм View и сохраняет его в binding
    /// - Parameters:
    ///   - frame: Binding для сохранения фрейма
    /// - Returns: View с отслеживанием фрейма
    func readFrame(into frame: Binding<CGRect>) -> some View {
        modifier(ViewFrameReader(frame: frame))
    }
}
