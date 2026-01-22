//
//  TopBarManager.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import SwiftUI

@Observable
@MainActor
class TopBarManager {
    static let shared = TopBarManager()
    
    var isVisible: Bool = true
    
    private init() {}
    
    func show() {
        isVisible = true
    }
    
    func hide() {
        isVisible = false
    }
}
