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
    
    var userState: UserStateService?
    
    init() {
        loadQuests()
        loadMiniGames()
    }
    
    private func loadQuests() {
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
    
    func completeQuest(_ quest: Quest) {
        guard !quest.isCompleted else { return }
        guard let userState = userState else { return }
        
        if let index = quests.firstIndex(where: { $0.id == quest.id }) {
            quests[index].isCompleted = true
            quests[index].progress = quests[index].maxProgress
            userState.addCoins(quest.reward)
            userState.addExperience(quest.reward / 2) // Опыт за выполнение квеста
            rewardMessage = "Выполнен квест: \(quest.title)! Получено \(quest.reward) койнов."
            showRewardAlert = true
        }
    }
    
    func playGame(_ game: MiniGame) {
        guard game.isAvailable else { return }
        guard let userState = userState else { return }
        
        // Имитация игры - просто начисляем награду
        userState.addCoins(game.reward)
        userState.addExperience(game.reward / 2) // Опыт за игру
        rewardMessage = "Вы прошли игру \(game.name)! Получено \(game.reward) койнов."
        showRewardAlert = true
    }
}
