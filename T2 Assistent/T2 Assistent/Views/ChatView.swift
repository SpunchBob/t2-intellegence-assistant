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
                                        showShopButton: index == 0 && viewModel.hasShopButton
                                    )
                                    .id(message.id)
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
                    .background(Color.tele2Pink)
                    .clipShape(Circle())
            }
            .disabled(messageText.isEmpty)
            
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Левая сторона - для сообщений ассистента
            if !message.isUser {
                Image(systemName: "face.smiling")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                
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

#Preview {
    NavigationStack {
        ChatView()
            .environment(UserStateService())
    }
}
