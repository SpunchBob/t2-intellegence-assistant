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

            // Карточка питомца
            HStack(spacing: 16) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color.tele2Pink)
                            .frame(width: 48, height: 48)

                        if tutorialManager.isPetEscaped {
                            Image(systemName: "questionmark")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        } else {
                            Image(userState.pet.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                        }
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
                    Text("\(petTypeName) помогает в играх!")
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
                    MiniGameCardNew(
                        game: game,
                        petIconName: userState.pet.iconName,
                        petTypeName: petTypeName
                    ) {
                        viewModel.playGame(game)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var completedQuestsCount: Int {
        viewModel.quests.filter { $0.isCompleted }.count
    }
    
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
    var petIconName: String = "FoxClassic"
    var petTypeName: String = "питомца"
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

                // Иконка питомца
                ZStack {
                    Circle()
                        .fill(Color.tele2Pink)
                        .frame(width: 24, height: 24)

                    if TutorialManager.shared.isPetEscaped {
                        Image(systemName: "questionmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Image(petIconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    }
                }
            }
            
            // Название игры
            Text(game.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.tele2Dark)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(game.maxReward) Койнов")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
            }

            Text("+\(game.bonusFromMax) бонус от \(petTypeName)")
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
