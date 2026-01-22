//
//  PetProfileView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import SwiftUI

struct PetProfileView: View {
    @Environment(UserStateService.self) private var userState
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Затемнение фона
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // Контент профиля
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Кнопка закрытия
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.tele2DarkSecondary)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Аватар
                        ZStack {
                            Circle()
                                .fill(Color.tele2Pink)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "face.smiling")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                        }
                        
                        // Имя
                        Text(userState.pet.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Уровень
                        HStack(spacing: 6) {
                            Image(systemName: "star")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            
                            Text("Уровень \(userState.pet.level)")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                        
                        // Опыт
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Опыт")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(userState.pet.experience) / 100 XP")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Фон прогресс-бара
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.tele2DarkSecondary)
                                        .frame(height: 8)
                                    
                                    // Прогресс
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.tele2Pink)
                                        .frame(
                                            width: geometry.size.width * CGFloat(min(userState.pet.experience, 100)) / 100,
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(.horizontal, 20)
                        
                        // Статистика
                        HStack(spacing: 16) {
                            StatCard(
                                value: "5",
                                label: "Игр сыграно",
                                color: .tele2Pink
                            )
                            
                            StatCard(
                                value: "10",
                                label: "Квестов выполнено",
                                color: Color(red: 0.0, green: 0.48, blue: 1.0) // Синий
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Особые способности
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Особые способности")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.tele2Pink)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                AbilityRow(
                                    icon: "sparkles",
                                    text: "+5% бонус к наградам в играх"
                                )
                                
                                AbilityRow(
                                    icon: "target",
                                    text: "Персональные рекомендации"
                                )
                                
                                AbilityRow(
                                    icon: "gift.fill",
                                    text: "Доступ к эксклюзивным квестам"
                                )
                            }
                        }
                        .padding(20)
                        .background(Color.tele2DarkSecondary)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        
                        
                        Spacer()
                            .frame(height: 20)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 40)
                }
                .background(Color.tele2Dark)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.tele2DarkSecondary)
        .cornerRadius(16)
    }
}

struct AbilityRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ZStack {
        Color.tele2Dark.ignoresSafeArea()
        PetProfileView(isPresented: .constant(true))
            .environment(UserStateService())
    }
}
