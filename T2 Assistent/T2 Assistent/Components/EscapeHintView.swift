//
//  EscapeHintView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import SwiftUI

struct EscapeHintView: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 12, weight: .semibold))
            
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.tele2Pink)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        Color.tele2Dark.ignoresSafeArea()
        EscapeHintView(text: "Вот тут его следы")
    }
}
