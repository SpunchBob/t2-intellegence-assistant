//
//  TopBarView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import SwiftUI

struct TopBarView: View {
    @Environment(UserStateService.self) private var userState
    @State private var topBarManager = TopBarManager.shared
    @State private var showPetProfile = false
    @ObservedObject private var tutorialManager = TutorialManager.shared
    
    var body: some View {
        if topBarManager.isVisible {
            unifiedTopBar
        }
    }
    
    private var unifiedTopBar: some View {
        HStack(spacing: 12) {
            // T2 Логотип
            ZStack {
                Circle()
                    .fill(Color.tele2Pink)
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.tele2Pink.opacity(0.5), radius: 8, x: 0, y: 0)
                Text("T2")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Текст "Интеллектуальный помощник"
            Text("Интеллектуальный помощник")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            // Иконка питомца с уведомлением
            Button(action: {
                withAnimation {
                    showPetProfile = true
                }
            }) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color.tele2Pink)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: tutorialManager.isPetEscaped ? "questionmark" : "face.smiling")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(tutorialManager.isPetEscaped ? .white : .orange)
                    }
                    
                    // Уведомление
                    Circle()
                        .fill(Color.tele2Pink)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Text("1")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 8, y: -8)
                }
            }
            
            // Иконка цепочки и Гигов в контейнере
            HStack(spacing: 6) {
                Image(systemName: "link")
                    .font(.system(size: 14))
                    .foregroundColor(.tele2Pink)
                
                Text("\(userState.coin.amount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Койнов")
                    .font(.system(size: 12))
                    .foregroundColor(.tele2Gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.tele2DarkSecondary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.tele2Pink, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.tele2Dark, Color.tele2DarkSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .popover(isPresented: $showPetProfile) {
            PetProfileView(isPresented: $showPetProfile)
                .environment(userState)
        }
    }
}

#Preview {
    VStack {
        TopBarView()
            .environment(UserStateService())
        Spacer()
    }
    .background(Color.tele2Dark)
}
