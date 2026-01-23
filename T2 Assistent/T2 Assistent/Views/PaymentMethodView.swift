//
//  PaymentMethodView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 23/1/26.
//

import SwiftUI

struct PaymentMethodView: View {
    @Environment(UserStateService.self) private var userState
    @Environment(\.dismiss) private var dismiss
    let amount: Double
    @State private var accountService = AccountService.shared
    @State private var paymentMethods: [PaymentMethod] = []
    @State private var selectedMethod: PaymentMethod?
    @State private var isLoading = true
    @State private var isProcessing = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.tele2Dark
                    .ignoresSafeArea()
                
                if isLoading && paymentMethods.isEmpty {
                    ProgressView()
                        .tint(.tele2Pink)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Заголовок
                            headerSection
                            
                            // Информация о сумме
                            amountInfoSection
                            
                            // Список способов оплаты
                            paymentMethodsSection
                            
                            // Кнопка оплаты
                            payButton
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
            .alert("Успешно", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Платеж на сумму \(formatAmount(amount)) ₽ успешно обработан")
            }
            .alert("Ошибка", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            loadPaymentMethods()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Способ оплаты")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Выберите удобный способ оплаты")
                .font(.system(size: 16))
                .foregroundColor(.tele2Gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Amount Info Section
    private var amountInfoSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Сумма пополнения")
                    .font(.system(size: 14))
                    .foregroundColor(.tele2Gray)
                
                Text("\(formatAmount(amount)) ₽")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.tele2DarkSecondary)
        .cornerRadius(16)
    }
    
    // MARK: - Payment Methods Section
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Выберите способ оплаты")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(paymentMethods) { method in
                    PaymentMethodCard(
                        method: method,
                        isSelected: selectedMethod?.id == method.id
                    ) {
                        if method.isAvailable {
                            selectedMethod = method
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Pay Button
    private var payButton: some View {
        Button(action: {
            processPayment()
        }) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("ОПЛАТИТЬ")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                selectedMethod != nil && !isProcessing ?
                Color.tele2Pink : Color.tele2Gray
            )
            .cornerRadius(12)
        }
        .disabled(selectedMethod == nil || isProcessing)
    }
    
    // MARK: - Helper Methods
    private func loadPaymentMethods() {
        Task {
            isLoading = true
            do {
                let methods = try await accountService.getPaymentMethods()
                await MainActor.run {
                    self.paymentMethods = methods
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Ошибка загрузки способов оплаты"
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func processPayment() {
        guard let method = selectedMethod else { return }
        
        isProcessing = true
        
        Task {
            do {
                let result = try await accountService.initiatePayment(amount: amount, method: method)
                
                await MainActor.run {
                    isProcessing = false
                    
                    if result.success {
                        showSuccessAlert = true
                    } else {
                        errorMessage = result.message
                        showErrorAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Ошибка обработки платежа: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
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

// MARK: - Payment Method Card
struct PaymentMethodCard: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Иконка
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.tele2Pink : Color.tele2DarkSecondary)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: method.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                // Информация
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    if let description = method.description {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.tele2Gray)
                    }
                }
                
                Spacer()
                
                // Индикатор выбора
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.tele2Pink)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.tele2Gray)
                }
            }
            .padding(16)
            .background(Color.tele2DarkSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.tele2Pink : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
            .opacity(method.isAvailable ? 1.0 : 0.6)
        }
        .disabled(!method.isAvailable)
    }
}

#Preview {
    PaymentMethodView(amount: 761.0)
        .environment(UserStateService())
}
