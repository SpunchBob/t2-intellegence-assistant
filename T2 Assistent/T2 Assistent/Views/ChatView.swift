//
//  ChatView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import SwiftUI

struct ChatView: View {
    @Environment(UserStateService.self) private var userState
    @State private var viewModel = ChatViewModel()
    @State private var messageText: String = ""
    @ObservedObject private var tutorialManager = TutorialManager.shared
    
    var body: some View {
        ZStack {
            // Темный фон
            Color.tele2Dark
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.messages.isEmpty {
                ProgressView()
                    .tint(.tele2Pink)
            } else {
                VStack(spacing: 0) {
                    // Список сообщений
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Заголовок
                                headerSection
                                
                                ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                                    MessageBubble(
                                        message: message,
                                        showShopButton: index == 0 && viewModel.hasShopButton,
                                        isPetEscaped: tutorialManager.isPetEscaped,
                                        petIconName: userState.pet.iconName
                                    )
                                    .id(message.id)
                                }
                                
                                // Индикатор "печатает..."
                                if viewModel.isTyping {
                                    TypingIndicator(
                                        isPetEscaped: tutorialManager.isPetEscaped,
                                        petIconName: userState.pet.iconName
                                    )
                                    .id("typing")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                        }
                        .onChange(of: viewModel.messages.count) { _ in
                            if let lastMessage = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isTyping) { _ in
                            if viewModel.isTyping {
                                withAnimation {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Быстрые действия
                    quickActionsSection
                    
                    // Поле ввода
                    inputSection
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(.tele2Pink)
                
                Text("Чем могу помочь?")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text("Задайте вопрос или выберите быстрое действие")
                .font(.system(size: 14))
                .foregroundColor(.tele2Gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                title: "Популярные тарифы",
                action: {
                    // Действие для тарифов
                }
            )
            
            QuickActionButton(
                title: "Проблемы со связью",
                action: {
                    // Действие для проблем
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("Напишите ваш вопрос...", text: $messageText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.tele2DarkSecondary)
                .cornerRadius(24)
                .onSubmit {
                    sendMessage()
                }
            
            // Кнопка отправки
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(messageText.isEmpty || viewModel.isTyping ? Color.tele2Pink.opacity(0.5) : Color.tele2Pink)
                    .clipShape(Circle())
            }
            .disabled(messageText.isEmpty || viewModel.isTyping)
            
            // Кнопка микрофона
            Button(action: {
                // Действие для голосового ввода
            }) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.tele2Pink)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.tele2Dark)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        viewModel.sendMessage(messageText)
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let showShopButton: Bool
    let isPetEscaped: Bool
    var petIconName: String = "FoxClassic"
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Левая сторона - для сообщений ассистента
            if !message.isUser {
                if isPetEscaped {
                    Image(systemName: "questionmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                } else {
                    Image(petIconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(showShopButton ? Color.tele2Pink : Color.white.opacity(0.1))
                        .cornerRadius(16)
                    
                    if showShopButton {
                        Button(action: {
                            // Переход в магазин
                        }) {
                            HStack {
                                Text("Перейти в магазин")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.tele2Pink)
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            
            // Правая сторона - для сообщений пользователя
            if message.isUser {
                Spacer(minLength: 0)
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.tele2Pink)
                        .cornerRadius(16)
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.tele2LightGray)
                .cornerRadius(20)
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    let isPetEscaped: Bool
    var petIconName: String = "FoxClassic"
    
    @State private var dotOffset: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isPetEscaped {
                Image(systemName: "questionmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
            } else {
                Image(petIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: dotOffset)
                        .animation(
                            Animation
                                .easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: dotOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .onAppear {
                dotOffset = -5
            }
            
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    NavigationStack {
        ChatView()
            .environment(UserStateService())
    }
}
