//
//  CoinsView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import SwiftUI

struct CoinsView: View {
    @Environment(UserStateService.self) private var userState
    @State private var viewModel = CoinsViewModel()
    @State private var timeRemaining: TimeInterval = 5 * 3600 + 12 * 60 + 25 // 5ч 12мин 25сек
    @ObservedObject private var tutorialManager = TutorialManager.shared

    // New state for games
    @State private var showTetris = false
    @State private var showSnake = false

    var body: some View {
        ZStack {
            Color.tele2Dark
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // Игровая зона
                        gamingZoneSection

                        // Ежедневные квесты
                        dailyQuestsSection

                        // Мини-игры
                        miniGamesSection
                    }
                    .padding(.bottom, 100) // Отступ для таббара
                }
                .onChange(of: tutorialManager.shouldScrollToViewId) { _, viewId in
                    if let viewId = viewId {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(viewId, anchor: .center)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.userState = userState
            startTimer()
            // Загружаем квесты с сервера
            viewModel.loadQuests()
        }
        .alert("Награда", isPresented: $viewModel.showRewardAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.rewardMessage)
        }
        .fullScreenCover(isPresented: $viewModel.showGameView) {
            if viewModel.selectedGame?.name == "Три в ряд" {
                MatchThreeGameView()
                    .environment(userState)
            }
        }
    }

    private var gamingZoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Игровая зона")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Зарабатывай Койны каждый день")
                .font(.system(size: 16))
                .foregroundColor(.tele2Gray)

            // Карточка Макса
            HStack(spacing: 16) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color.tele2Pink)
                            .frame(width: 48, height: 48)

                            Image(systemName: tutorialManager.isPetEscaped ? "questionmark" : "face.smiling")
                                .font(.system(size: 24, weight: .semibold))
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
                        .offset(x: 4, y: -4)
                }
                

                VStack(alignment: .leading, spacing: 8) {
                    Text("Макс помогает в играх!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.tele2Pink)

                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)

                        Text("Бонус к наградам: +5 Койнов")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(Color.tele2DarkSecondary)
            .cornerRadius(16)
            .withTutorialSupport(viewId: "123")
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var dailyQuestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок с таймером
            HStack {
                Text("Ежедневные квесты")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)

                    Text(timeString(from: timeRemaining))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
            }

            // Прогресс-бар
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Прогресс")
                        .font(.system(size: 14))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(completedQuestsCount)/\(viewModel.quests.count) выполнено")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.tele2DarkSecondary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.tele2Pink)
                            
                    }
                }
                .frame(height: 8)
            }

            // Список квестов
            VStack(spacing: 12) {
                if viewModel.isLoadingQuests {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .tele2Pink))
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else if let error = viewModel.questsError {
                    Text("Ошибка: \(error)")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ForEach(viewModel.quests) { quest in
                        QuestRowCard(quest: quest) {
                            viewModel.completeQuest(quest)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var miniGamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Мини-игры")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.miniGames) { game in
                    MiniGameCardNew(game: game) {
                        // Use local handler: if special games then open local views, otherwise delegate to VM
                        if game.name == "Тетрис" {
                            showTetris = true
                        } else if game.name == "Змейка" {
                            showSnake = true
                        } else {
                            viewModel.playGame(game)
                        }
                    }
                }

                // Additional explicit cards for Tetris and Snake in case viewModel doesn't include them
                MiniGameCardNew(game: MiniGame(name: "Тетрис", description: "", iconName: "square.grid.3x3.fill", maxReward: 100, bonusFromMax: 10, color: "pink")) {
                    showTetris = true
                }

                MiniGameCardNew(game: MiniGame(name: "Змейка", description: "", iconName: "hare.fill", maxReward: 80, bonusFromMax: 8, color: "pink")) {
                    showSnake = true
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var completedQuestsCount: Int {
        viewModel.quests.filter { $0.isCompleted }.count
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timeRemaining = 24 * 3600 // Сброс на 24 часа
            }
        }
    }
}

struct QuestRowCard: View {
    let quest: Quest
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Чекбокс
            ZStack {
                Circle()
                    .fill(quest.isCompleted ? Color.tele2Pink : Color.clear)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(quest.isCompleted ? Color.tele2Pink : Color.tele2Gray, lineWidth: 2)
                    )

                if quest.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Текст квеста
            Text(quest.title)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer()

            // Награда
            HStack(spacing: 4) {
                Text("+\(quest.reward)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.tele2Pink)

                Image(systemName: "target")
                    .font(.system(size: 14))
                    .foregroundColor(.tele2Pink)
            }
        }
        .padding(16)
        .background(Color.tele2DarkSecondary)
        .cornerRadius(12)
        .onTapGesture {
            if !quest.isCompleted {
                onComplete()
            }
        }
    }
}

struct MiniGameCardNew: View {
    let game: MiniGame
    let onPlay: () -> Void

    var iconColor: Color {
        switch game.color {
        case "pink": return .tele2Pink
        case "blue": return Color(red: 0.0, green: 0.7, blue: 1.0)
        case "yellow": return .yellow
        case "green": return Color(red: 0.0, green: 0.8, blue: 0.4)
        default: return .tele2Pink
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Иконка игры
                Image(systemName: game.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)

                Spacer()

                // Иконка лисы
                ZStack {
                    Circle()
                        .fill(Color.tele2Pink)
                        .frame(width: 24, height: 24)

                    Image(systemName: TutorialManager.shared.isPetEscaped ? "questionmark" : "face.smiling")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(TutorialManager.shared.isPetEscaped ? .white : .orange)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Макс. выигрыш: \(game.maxReward) Койнов")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text("\(game.maxReward) Койнов")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
            }

            Text("+\(game.bonusFromMax) бонус от Макс")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.0, green: 0.7, blue: 1.0))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .onTapGesture {
            if game.isAvailable {
                onPlay()
            }
        }
    }
}

#Preview {
    NavigationStack {
        CoinsView()
            .environment(UserStateService())
    }
}
