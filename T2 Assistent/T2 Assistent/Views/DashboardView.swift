//
//  DashboardView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import SwiftUI

struct DashboardView: View {
    @Environment(UserStateService.self) private var userState
    @State private var accountService = AccountService.shared
    @State private var account: Account?
    @State private var isLoading = true
    @State private var showTopUp = false
    @State private var promotionCards: [PromotionCard] = []
    @ObservedObject private var tutorialManager = TutorialManager.shared
    
    var body: some View {
        ZStack {
            Color.tele2Dark
                .ignoresSafeArea()
            
            if isLoading && account == nil {
                ProgressView()
                    .tint(.tele2Pink)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Карточки предложений
                        promotionCardsSection
                            .padding(.top, 16)
                        
                        // Секция "Мой номер"
                        myNumberSection
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                        
                        // Основной контент на белом фоне
                        VStack(spacing: 0) {
                            // Промо баннер
                            promoBanner
                                .padding(.top, 20)
                                .padding(.horizontal, 16)
                            
                            // Секция баланса
                            balanceSection
                                .padding(.top, 16)
                                .padding(.horizontal, 16)
                            
                            // Рекомендация по пополнению
                            if let requiredTopUp = account?.requiredTopUp {
                                topUpRecommendation(amount: requiredTopUp)
                                    .padding(.top, 12)
                                    .padding(.horizontal, 16)
                            }
                            
                            // Кнопка "Управление ГБ и минутами"
                            gbAndMinutesButton
                                .padding(.top, 16)
                                .padding(.horizontal, 16)
                            
                            // Секция "Подарки каждому"
                            giftsSection
                                .padding(.top, 24)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 100)
                        }
                        .background(Color.white)
                        .cornerRadius(20, corners: [.topLeft, .topRight])
                        .padding(.top, 16)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadData()
            tutorialManager.startPetEscapeTutorialIfNeeded()
        }
        .onChange(of: showTopUp) { _, newValue in
            if !newValue {
                // Обновляем данные после закрытия экрана пополнения
                loadData()
            }
        }
        .navigationDestination(isPresented: $showTopUp) {
            TopUpView()
                .environment(userState)
        }
    }
    
    // MARK: - Promotion Cards Section
    private var promotionCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(promotionCards) { card in
                    PromotionCardView(card: card)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - My Number Section
    private var myNumberSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if let account = account {
                    NumberCard(phoneNumber: account.phoneNumber)
                }
                // Можно добавить дополнительные номера
            }
        }
    }
    
    // MARK: - Promo Banner
    private var promoBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.0, green: 0.8, blue: 0.4))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            Text("Пополнение, автоплатежи и переводы в новом разделе")
                .font(.system(size: 14))
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Balance Section
    private var balanceSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let account = account {
                    Text("\(formatBalance(account.balance)) ₽")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.red)
                    
                    Text("Тариф заблокирован")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: {
                showTopUp = true
            }) {
                Text("ПОПОЛНИТЬ")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .cornerRadius(8)
            }
            .overlay(alignment: .topTrailing) {
                if shouldShowEscapeHint {
                    EscapeHintView(text: "Вот тут его следы")
                        .offset(x: 12, y: -24)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Top Up Recommendation
    private func topUpRecommendation(amount: Double) -> some View {
        HStack {
            Text("Пополните баланс на \(formatBalance(amount)) ₽, чтобы продолжить пользоваться услугами связи в полном объеме")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - GB and Minutes Button
    private var gbAndMinutesButton: some View {
        Button(action: {}) {
            HStack {
                Text("Управление ГБ и минутами")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                    
                    Text("1")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.5, green: 0.0, blue: 0.8), Color(red: 0.7, green: 0.0, blue: 1.0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }
    
    // MARK: - Gifts Section
    private var giftsSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ПОДАРКИ КАЖДОМУ")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Дарите близким или забирайте себе")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Иконка подарка
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.3, blue: 0.5),
                                Color(red: 0.9, green: 0.1, blue: 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "gift.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private func loadData() {
        Task {
            isLoading = true
            do {
                let loadedAccount = try await accountService.loadAccount()
                await MainActor.run {
                    self.account = loadedAccount
                    self.promotionCards = [
                        PromotionCard(
                            title: "Интернет и SMS ограничены на 24 часа",
                            backgroundColor: "pink"
                        ),
                        PromotionCard(
                            title: "Встречайте SAFEWALL",
                            subtitle: nil,
                            iconName: "lock.fill",
                            iconColor: "pink",
                            backgroundColor: "green",
                            borderColor: "green"
                        ),
                        PromotionCard(
                            title: "Игра «Новогодний Апгрейд»",
                            subtitle: nil,
                            iconName: "snowflake",
                            iconColor: "blue",
                            backgroundColor: "blue",
                            borderColor: "green"
                        ),
                        PromotionCard(
                            title: "Получите до 2000 ₽",
                            subtitle: nil,
                            iconName: "rublesign.circle.fill",
                            iconColor: "green",
                            backgroundColor: "green",
                            borderColor: "green"
                        )
                    ]
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func formatBalance(_ balance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: balance)) ?? "0.00"
    }

    private var shouldShowEscapeHint: Bool {
        tutorialManager.isPetEscaped &&
        tutorialManager.currentStep?.id == "petEscapeDashboardTopUp"
    }

}

// MARK: - Promotion Card View
struct PromotionCardView: View {
    let card: PromotionCard
    
    var backgroundColor: Color {
        switch card.backgroundColor {
        case "pink": return .tele2Pink
        case "green": return Color(red: 0.0, green: 0.8, blue: 0.4)
        case "blue": return Color(red: 0.0, green: 0.7, blue: 1.0)
        default: return .tele2Pink
        }
    }
    
    var borderColor: Color? {
        guard let border = card.borderColor else { return nil }
        switch border {
        case "green": return Color(red: 0.0, green: 0.8, blue: 0.4)
        default: return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if let iconName = card.iconName {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                        .frame(width: 80, height: 80)
                    
                    if iconName == "lock.fill" {
                        // Специальная иконка замка с отпечатком
                        ZStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                            
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .offset(x: 8, y: -8)
                        }
                    } else if iconName == "snowflake" {
                        // Новогодний мотив
                        Image(systemName: "snowflake")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    } else if iconName == "rublesign.circle.fill" {
                        Image(systemName: "rublesign.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
            }
            
            Text(card.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 120, height: 140)
        .padding(12)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor ?? Color.clear, lineWidth: 2)
        )
        .cornerRadius(12)
    }
}

// MARK: - Number Card
struct NumberCard: View {
    let phoneNumber: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Мой номер")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            Text(phoneNumber)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.tele2DarkSecondary)
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(UserStateService())
    }
}
