//
//  MatchThreeGameViewModel.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import SwiftUI

@Observable
@MainActor
class MatchThreeGameViewModel {
    var tiles: [[MatchThreeTile]] = []
    var score: Int = 0
    var moves: Int = 30
    var targetScore: Int = 200
    var isGameOver: Bool = false
    var isWon: Bool = false
    var selectedTile: (row: Int, col: Int)? = nil
    var reward: Int = 0
    
    private let rows = 8
    private let cols = 8
    private var userState: UserStateService?
    
    init() {
        startNewGame()
    }
    
    func setUserState(_ userState: UserStateService) {
        self.userState = userState
    }
    
    func startNewGame() {
        score = 0
        moves = 30
        targetScore = 200
        isGameOver = false
        isWon = false
        selectedTile = nil
        reward = 0
        
        // Создаем игровое поле
        tiles = []
        for row in 0..<rows {
            var rowTiles: [MatchThreeTile] = []
            for col in 0..<cols {
                let type = TileType.allCases.randomElement()!
                rowTiles.append(MatchThreeTile(type: type, row: row, col: col))
            }
            tiles.append(rowTiles)
        }
        
        // Убираем начальные совпадения
        removeInitialMatches()
    }
    
    private func removeInitialMatches() {
        var hasMatches = true
        while hasMatches {
            hasMatches = false
            for row in 0..<rows {
                for col in 0..<cols {
                    if findMatches(at: row, col: col).count >= 3 {
                        tiles[row][col].type = TileType.allCases.randomElement()!
                        hasMatches = true
                    }
                }
            }
        }
    }
    
    func selectTile(row: Int, col: Int) {
        guard !isGameOver else { return }
        guard row >= 0 && row < rows && col >= 0 && col < cols else { return }
        
        if let selected = selectedTile {
            // Пытаемся поменять местами
            if (selected.row == row && abs(selected.col - col) == 1) ||
               (selected.col == col && abs(selected.row - row) == 1) {
                swapTiles(row1: selected.row, col1: selected.col, row2: row, col2: col)
                selectedTile = nil
            } else {
                // Выбираем новую плитку
                selectedTile = (row, col)
            }
        } else {
            selectedTile = (row, col)
        }
    }
    
    private func swapTiles(row1: Int, col1: Int, row2: Int, col2: Int) {
        let temp = tiles[row1][col1].type
        tiles[row1][col1].type = tiles[row2][col2].type
        tiles[row2][col2].type = temp
        
        // Проверяем совпадения после обмена
        let matches1 = findMatches(at: row1, col: col1)
        let matches2 = findMatches(at: row2, col: col2)
        
        if matches1.count >= 3 || matches2.count >= 3 {
            moves -= 1
            processMatches()
        } else {
            // Возвращаем обратно, если нет совпадений
            let temp = tiles[row1][col1].type
            tiles[row1][col1].type = tiles[row2][col2].type
            tiles[row2][col2].type = temp
        }
    }
    
    private func processMatches() {
        var allMatches: Set<UUID> = []
        
        // Находим все совпадения
        for row in 0..<rows {
            for col in 0..<cols {
                let matches = findMatches(at: row, col: col)
                if matches.count >= 3 {
                    allMatches.formUnion(matches)
                }
            }
        }
        
        if allMatches.isEmpty {
            checkGameOver()
            return
        }
        
        // Удаляем совпадения и начисляем очки
        let matchCount = allMatches.count
        score += matchCount * 10
        
        // Удаляем плитки
        for row in 0..<rows {
            for col in 0..<cols {
                if allMatches.contains(tiles[row][col].id) {
                    tiles[row][col].isMatched = true
                }
            }
        }
        
        // Плитки падают вниз
        dropTiles()
        
        // Заполняем пустые места
        fillEmptySpaces()
        
        // Проверяем новые совпадения после падения (с небольшой задержкой для анимации)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            processMatches()
        }
    }
    
    private func findMatches(at row: Int, col: Int) -> Set<UUID> {
        var matches: Set<UUID> = [tiles[row][col].id]
        let type = tiles[row][col].type
        
        // Проверяем горизонтальные совпадения
        var horizontalMatches: Set<UUID> = [tiles[row][col].id]
        // Влево
        var leftCol = col - 1
        while leftCol >= 0 && tiles[row][leftCol].type == type {
            horizontalMatches.insert(tiles[row][leftCol].id)
            leftCol -= 1
        }
        // Вправо
        var rightCol = col + 1
        while rightCol < cols && tiles[row][rightCol].type == type {
            horizontalMatches.insert(tiles[row][rightCol].id)
            rightCol += 1
        }
        
        // Проверяем вертикальные совпадения
        var verticalMatches: Set<UUID> = [tiles[row][col].id]
        // Вверх
        var upRow = row - 1
        while upRow >= 0 && tiles[upRow][col].type == type {
            verticalMatches.insert(tiles[upRow][col].id)
            upRow -= 1
        }
        // Вниз
        var downRow = row + 1
        while downRow < rows && tiles[downRow][col].type == type {
            verticalMatches.insert(tiles[downRow][col].id)
            downRow += 1
        }
        
        // Выбираем наибольшее совпадение
        if horizontalMatches.count >= 3 {
            matches.formUnion(horizontalMatches)
        }
        if verticalMatches.count >= 3 {
            matches.formUnion(verticalMatches)
        }
        
        return matches.count >= 3 ? matches : []
    }
    
    private func dropTiles() {
        for col in 0..<cols {
            var writeIndex = rows - 1
            for row in stride(from: rows - 1, through: 0, by: -1) {
                if !tiles[row][col].isMatched {
                    if writeIndex != row {
                        tiles[writeIndex][col] = tiles[row][col]
                        tiles[writeIndex][col].row = writeIndex
                    }
                    writeIndex -= 1
                }
            }
        }
    }
    
    private func fillEmptySpaces() {
        for col in 0..<cols {
            for row in 0..<rows {
                if tiles[row][col].isMatched {
                    tiles[row][col] = MatchThreeTile(
                        type: TileType.allCases.randomElement()!,
                        row: row,
                        col: col
                    )
                    tiles[row][col].isMatched = false
                }
            }
        }
    }
    
    private func checkGameOver() {
        if moves <= 0 {
            isGameOver = true
            if score >= targetScore {
                isWon = true
                calculateReward()
                awardReward()
            }
        } else if score >= targetScore {
            isGameOver = true
            isWon = true
            calculateReward()
            awardReward()
        }
    }
    
    private func calculateReward() {
        // Базовая награда + бонус за превышение цели
        let baseReward = 50
        let bonus = max(0, (score - targetScore) / 100)
        reward = baseReward + bonus
    }
    
    private func awardReward() {
        guard let userState = userState else { return }
        
        // Отправляем награду на бэкенд
        Task {
            await userState.addCoins(reward)
        }
    }
}
