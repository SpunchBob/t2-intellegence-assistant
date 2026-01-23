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
    @ObservedObject private var tutorialManager = TutorialManager.shared
    
    /// Открыть сразу в режиме редактирования
    var startInEditMode: Bool = false
    
    // Режим редактирования
    @State private var isEditing = false
    @State private var selectedType: String = ""
    @State private var selectedCrown: String = ""
    @State private var isSaving = false
    
    // Доступные опции
    private let petTypes = [
        PetOption(id: "dragon", name: "Дракон", icon: "DragonClassic"),
        PetOption(id: "fox", name: "Лис", icon: "FoxClassic")
    ]
    
    private let crowns = [
        CrownOption(id: "none", name: "Без аксессуара", icon: "xmark.circle"),
        CrownOption(id: "crown", name: "Корона", icon: "crown.fill")
    ]
    
    /// Отображаемое имя типа питомца
    private var petTypeName: String {
        switch userState.pet.type.lowercased() {
        case "dragon": return "Дракон"
        case "fox": return "Лис"
        case "cat": return "Кот"
        case "dog": return "Собака"
        default: return userState.pet.type.capitalized
        }
    }
    
    /// Отображаемое имя короны
    private var crownName: String {
        switch userState.pet.crown.lowercased() {
        case "hat": return "Шляпа"
        case "crown": return "Корона"
        case "cap": return "Кепка"
        case "none", "": return ""
        default: return userState.pet.crown.capitalized
        }
    }
    
    var body: some View {
        ZStack {
            // Затемнение фона
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isEditing {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            
            // Контент профиля
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Заголовок с кнопками
                        headerSection
                        
                        // Аватар
                        avatarSection
                        
                        if isEditing {
                            // Режим редактирования
                            editingSection
                        } else {
                            // Режим просмотра
                            viewingSection
                        }
                        
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
        .onAppear {
            // Инициализируем выбранные значения
            selectedType = userState.pet.type
            selectedCrown = userState.pet.crown
            
            // Если запрошен режим редактирования - включаем его
            if startInEditMode && !tutorialManager.isPetEscaped {
                isEditing = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            if isEditing {
                Button(action: {
                    withAnimation {
                        // Отмена - возвращаем исходные значения
                        selectedType = userState.pet.type
                        selectedCrown = userState.pet.crown
                        isEditing = false
                    }
                }) {
                    Text("Отмена")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.tele2Gray)
                }
            } else {
                Spacer()
            }
            
            Spacer()
            
            if isEditing {
                Button(action: {
                    saveChanges()
                }) {
                    if isSaving {
                        ProgressView()
                            .tint(.tele2Pink)
                            .frame(width: 32, height: 32)
                    } else {
                        Text("Сохранить")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.tele2Pink)
                    }
                }
                .disabled(isSaving)
            } else {
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
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        ZStack {
            Circle()
                .fill(Color.tele2Pink)
                .frame(width: 120, height: 120)
            
            if tutorialManager.isPetEscaped {
                Image(systemName: "questionmark")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundColor(.white)
            } else {
                // Показываем превью выбранного типа в режиме редактирования
                let iconName = isEditing ? previewIconName : userState.pet.iconName
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            }
            
            // Кнопка редактирования на аватаре
            if !isEditing && !tutorialManager.isPetEscaped {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                isEditing = true
                            }
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.tele2Pink)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.tele2Dark, lineWidth: 2)
                                )
                        }
                    }
                }
                .frame(width: 120, height: 120)
            }
        }
    }
    
    /// Превью иконки питомца на основе выбранных опций
    private var previewIconName: String {
        let typeName = selectedType.capitalized
        let crownSuffix = selectedCrown.isEmpty || selectedCrown == "none" ? "Classic" : "Crown"
        return "\(typeName)\(crownSuffix)"
    }
    
    // MARK: - Viewing Section
    
    private var viewingSection: some View {
        VStack(spacing: 24) {
            // Тип питомца (или сообщение о побеге)
            Text(tutorialManager.isPetEscaped ? "Я КУДА-ТО СБЕЖАЛ..." : petTypeName)
                .font(.system(size: tutorialManager.isPetEscaped ? 24 : 32, weight: .bold))
                .foregroundColor(tutorialManager.isPetEscaped ? .tele2Pink : .white)
                .multilineTextAlignment(.center)
            
            // Корона
            if !userState.pet.crown.isEmpty && userState.pet.crown != "none" {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                    
                    Text(crownName)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
            }
            
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
                    color: Color(red: 0.0, green: 0.48, blue: 1.0)
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
        }
    }
    
    // MARK: - Editing Section
    
    private var editingSection: some View {
        VStack(spacing: 24) {
            // Выбор типа питомца
            VStack(alignment: .leading, spacing: 12) {
                Text("Тип питомца")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(petTypes, id: \.id) { option in
                            PetTypeCard(
                                option: option,
                                isSelected: selectedType.lowercased() == option.id,
                                onSelect: {
                                    withAnimation {
                                        selectedType = option.id
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Выбор аксессуара
            VStack(alignment: .leading, spacing: 12) {
                Text("Аксессуар")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(crowns, id: \.id) { option in
                            CrownCard(
                                option: option,
                                isSelected: selectedCrown.lowercased() == option.id,
                                onSelect: {
                                    withAnimation {
                                        selectedCrown = option.id
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        isSaving = true
        
        Task {
            // Создаём обновлённого питомца
            var updatedPet = userState.pet
            updatedPet.type = selectedType
            updatedPet.crown = selectedCrown
            
            // Обновляем через сервис
            await userState.updatePet(updatedPet)
            
            await MainActor.run {
                isSaving = false
                withAnimation {
                    isEditing = false
                }
            }
        }
    }
}

// MARK: - Supporting Models

struct PetOption {
    let id: String
    let name: String
    let icon: String
}

struct CrownOption {
    let id: String
    let name: String
    let icon: String
}

// MARK: - Selection Cards

struct PetTypeCard: View {
    let option: PetOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.tele2Pink : Color.tele2DarkSecondary)
                        .frame(width: 64, height: 64)
                    
                    Image(option.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
                
                Text(option.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .tele2Pink : .white)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.tele2DarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.tele2Pink : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct CrownCard: View {
    let option: CrownOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: option.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .yellow : .white)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.yellow.opacity(0.2) : Color.tele2DarkSecondary)
                    )
                
                Text(option.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .tele2Pink : .white)
                    .lineLimit(1)
            }
            .frame(width: 90)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.tele2DarkSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.tele2Pink : Color.clear, lineWidth: 2)
                    )
            )
        }
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
