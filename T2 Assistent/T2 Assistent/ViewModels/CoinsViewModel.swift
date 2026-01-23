//
//  CoinsViewModel.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

@Observable
@MainActor
class CoinsViewModel {
    var quests: [Quest] = []
    var miniGames: [MiniGame] = []
    var showRewardAlert = false
    var rewardMessage = ""
    var isLoadingQuests = false
    var questsError: String?
    
    var userState: UserStateService?
    
    private let questService = QuestService.shared
    
    init() {
        loadMiniGames()
    }
    
    /// Загрузка квестов с сервера
    func loadQuests() {
        isLoadingQuests = true
        questsError = nil
        
        Task {
            do {
                let loadedQuests = try await questService.loadDailyQuests()
                
                await MainActor.run {
                    self.quests = loadedQuests
                    self.isLoadingQuests = false
                }
            } catch {
                await MainActor.run {
                    self.questsError = error.localizedDescription
                    self.isLoadingQuests = false
                    // Загружаем локальные данные при ошибке
                    self.loadLocalQuests()
                }
                print("Error loading quests: \(error)")
            }
        }
    }
    
    private func loadLocalQuests() {
        quests = [
            Quest(
                title: "Зайти в приложение",
                description: "",
                reward: 10,
                isCompleted: true,
                progress: 1,
                maxProgress: 1
            ),
            Quest(
                title: "Проверить баланс",
                description: "",
                reward: 10,
                isCompleted: true,
                progress: 1,
                maxProgress: 1
            ),
            Quest(
                title: "Использовать помощника",
                description: "",
                reward: 20,
                isCompleted: false,
                progress: 0,
                maxProgress: 1
            ),
            Quest(
                title: "Купить что-то в магазине",
                description: "",
                reward: 50,
                isCompleted: false,
                progress: 0,
                maxProgress: 1
            ),
            Quest(
                title: "Сыграть в одну игру",
                description: "",
                reward: 30,
                isCompleted: false,
                progress: 0,
                maxProgress: 1
            )
        ]
    }
    
    private func loadMiniGames() {
        miniGames = [
            MiniGame(
                name: "Три в ряд",
                description: "",
                iconName: "grid.circle.fill",
                maxReward: 50,
                bonusFromMax: 5,
                color: "pink"
            ),
            MiniGame(
                name: "Спам-отбивалка",
                description: "",
                iconName: "bolt.fill",
                maxReward: 50,
                bonusFromMax: 5,
                color: "pink"
            ),
            MiniGame(
                name: "Пазл eSIM",
                description: "",
                iconName: "puzzlepiece.fill",
                maxReward: 40,
                bonusFromMax: 5,
                color: "blue"
            ),
            MiniGame(
                name: "Гонка сигнала",
                description: "",
                iconName: "car.fill",
                maxReward: 60,
                bonusFromMax: 5,
                color: "yellow"
            ),
            MiniGame(
                name: "Викторина Т2",
                description: "",
                iconName: "brain.head.profile",
                maxReward: 45,
                bonusFromMax: 5,
                color: "green"
            )
        ]
    }
    
    /// Выполнение квеста через API
    func completeQuest(_ quest: Quest) {
        guard !quest.isCompleted else { return }
        guard let userState = userState else { return }
        
        Task {
            do {
                // Вызываем API для выполнения квеста
                let result = try await questService.completeQuest(quest)
                
                await MainActor.run {
                    if result.success {
                        // Удаляем квест из списка (API возвращает только невыполненные)
                        self.quests.removeAll { $0.id == quest.id }
                        
                        // Начисляем награду локально (сервер уже начислил на баланс)
                        // Перезагружаем баланс для синхронизации
                        Task {
                            await userState.loadBalance()
                            userState.addCoinsLocally(quest.reward / 2)
                        }
                        
                        
                        
                        self.rewardMessage = "Выполнен квест: \(quest.title)! Получено \(quest.reward) койнов."
                        self.showRewardAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    // Если API недоступен, выполняем локально
                    if let index = self.quests.firstIndex(where: { $0.id == quest.id }) {
                        self.quests[index].isCompleted = true
                        self.quests[index].progress = self.quests[index].maxProgress
                        userState.addCoinsLocally(quest.reward)
                        self.rewardMessage = "Выполнен квест: \(quest.title)! Получено \(quest.reward) койнов."
                        self.showRewardAlert = true
                    }
                }
                print("Error completing quest: \(error)")
            }
        }
    }
    
    var selectedGame: MiniGame?
    var showGameView = false
    
    func playGame(_ game: MiniGame) {
        guard game.isAvailable else { return }
        
        // Для игры "Три в ряд" открываем специальный экран
        if game.name == "Три в ряд" {
            selectedGame = game
            showGameView = true
        } else {
            // Для других игр - имитация
            guard let userState = userState else { return }
            userState.addCoinsLocally(game.reward)
            rewardMessage = "Вы прошли игру \(game.name)! Получено \(game.reward) койнов."
            showRewardAlert = true
        }
    }
}
