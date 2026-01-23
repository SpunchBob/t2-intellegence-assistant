//
//  TopUpView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import SwiftUI

struct TopUpView: View {
    @Environment(UserStateService.self) private var userState
    @Environment(\.dismiss) private var dismiss
    @State private var accountService = AccountService.shared
    @State private var account: Account?
    @State private var topUpAmounts: [TopUpAmount] = []
    @State private var selectedAmount: TopUpAmount?
    @State private var customAmount: String = ""
    @State private var isLoading = true
    @State private var showPaymentMethod = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.tele2Dark
                    .ignoresSafeArea()
                
                if isLoading && topUpAmounts.isEmpty {
                    ProgressView()
                        .tint(.tele2Pink)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Заголовок
                            headerSection
                            
                            // Информация о балансе
                            if let account = account {
                                balanceInfoSection(account: account)
                            }
                            
                            // Список сумм пополнения
                            amountsSection
                            
                            // Поле для ввода своей суммы
                            customAmountSection
                            
                            // Кнопка пополнения
                            topUpButton
                                .padding(.bottom, 40)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showPaymentMethod) {
                if let selectedAmount = selectedAmount {
                    PaymentMethodView(amount: selectedAmount.amount)
                        .environment(userState)
                }
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Пополнение баланса")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Выберите сумму пополнения")
                .font(.system(size: 16))
                .foregroundColor(.tele2Gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Balance Info Section
    private func balanceInfoSection(account: Account) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Текущий баланс")
                    .font(.system(size: 14))
                    .foregroundColor(.tele2Gray)
                
                Text("\(formatBalance(account.balance)) ₽")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            if let requiredTopUp = account.requiredTopUp {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Для разблокировки")
                        .font(.system(size: 14))
                        .foregroundColor(.tele2Gray)
                    
                    Text("+\(formatBalance(requiredTopUp)) ₽")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.tele2Pink)
                }
            }
        }
        .padding(20)
        .background(Color.tele2DarkSecondary)
        .cornerRadius(16)
    }
    
    // MARK: - Amounts Section
    private var amountsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Выберите сумму")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(topUpAmounts) { amount in
                    AmountCard(
                        amount: amount,
                        isSelected: selectedAmount?.id == amount.id
                    ) {
                        selectedAmount = amount
                        customAmount = ""
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Amount Section
    private var customAmountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Или введите свою сумму")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            HStack {
                TextField("Сумма", text: $customAmount)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(Color.tele2DarkSecondary)
                    .cornerRadius(12)
                    .onChange(of: customAmount) { _, newValue in
                        if !newValue.isEmpty {
                            selectedAmount = nil
                        }
                    }
                
                Text("₽")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Top Up Button
    private var topUpButton: some View {
        Button(action: {
            if let selected = selectedAmount {
                showPaymentMethod = true
            } else if let custom = Double(customAmount), custom > 0 {
                let customTopUp = TopUpAmount(amount: custom)
                selectedAmount = customTopUp
                showPaymentMethod = true
            }
        }) {
            Text("ПОПОЛНИТЬ")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    (selectedAmount != nil || (Double(customAmount) ?? 0) > 0) ?
                    Color.tele2Pink : Color.tele2Gray
                )
                .cornerRadius(12)
        }
        .disabled(selectedAmount == nil && (Double(customAmount) ?? 0) <= 0)
    }
    
    // MARK: - Helper Methods
    private func loadData() {
        Task {
            isLoading = true
            do {
                async let accountTask = accountService.loadAccount()
                async let amountsTask = accountService.getTopUpAmounts()
                
                let (loadedAccount, loadedAmounts) = try await (accountTask, amountsTask)
                
                await MainActor.run {
                    self.account = loadedAccount
                    self.topUpAmounts = loadedAmounts
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
}

// MARK: - Amount Card
struct AmountCard: View {
    let amount: TopUpAmount
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                HStack {
                    Text("\(formatAmount(amount.amount)) ₽")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isSelected ? .tele2Pink : .white)
                    
                    Spacer()
                }
                
                if let bonus = amount.bonus, bonus > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.tele2Pink)
                        
                        Text("+\(formatAmount(bonus)) ₽")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.tele2Pink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if amount.isRecommended {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.tele2Pink)
                        
                        Text("Рекомендуется")
                            .font(.system(size: 12))
                            .foregroundColor(.tele2Pink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .frame(height: 100)
            .background(isSelected ? Color.white : Color.tele2DarkSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.tele2Pink : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", amount)
        } else {
            return String(format: "%.2f", amount)
        }
    }
}

#Preview {
    TopUpView()
        .environment(UserStateService())
}
