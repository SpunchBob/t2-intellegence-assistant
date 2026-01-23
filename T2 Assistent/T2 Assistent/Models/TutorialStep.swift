//
//  TutorialStep.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import SwiftUI

/// Модель шага туториала
struct TutorialStep: Identifiable {
    let id: String
    let title: String
    let description: String
    let targetViewId: String? // ID целевого View для выделения
    let position: TutorialPosition // Позиция текста относительно выделенного объекта
    
    enum TutorialPosition {
        case top
        case bottom
        case left
        case right
        case center
    }
}

