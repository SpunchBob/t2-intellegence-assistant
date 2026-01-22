//
//  MatchThreeGameView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import SwiftUI

struct MatchThreeGameView: View {
    @Environment(UserStateService.self) private var userState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MatchThreeGameViewModel()
    
    private let tileSize: CGFloat = 40
    private let spacing: CGFloat = 4
    
    var body: some View {
        ZStack {
            Color.tele2Dark
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Заголовок и кнопка закрытия
                HStack {
                    Text("Три в ряд")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.tele2DarkSecondary)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Статистика игры
                HStack(spacing: 20) {
                    StatBox(title: "Очки", value: "\(viewModel.score)", color: .tele2Pink)
                    StatBox(title: "Ходы", value: "\(viewModel.moves)", color: .blue)
                    StatBox(title: "Цель", value: "\(viewModel.targetScore)", color: .green)
                }
                .padding(.horizontal, 16)
                
                // Игровое поле
                VStack(spacing: spacing) {
                    ForEach(0..<viewModel.tiles.count, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<viewModel.tiles[row].count, id: \.self) { col in
                                TileView(
                                    tile: viewModel.tiles[row][col],
                                    size: tileSize,
                                    isSelected: viewModel.selectedTile?.row == row && viewModel.selectedTile?.col == col
                                ) {
                                    viewModel.selectTile(row: row, col: col)
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.tele2DarkSecondary)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Кнопка новой игры
                Button(action: {
                    viewModel.startNewGame()
                }) {
                    Text("Новая игра")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.tele2Pink)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            
            // Модальное окно окончания игры
            if viewModel.isGameOver {
                GameOverModal(
                    isWon: viewModel.isWon,
                    score: viewModel.score,
                    reward: viewModel.reward,
                    onDismiss: {
                        dismiss()
                    },
                    onNewGame: {
                        viewModel.startNewGame()
                    }
                )
            }
        }
        .onAppear {
            viewModel.setUserState(userState)
        }
    }
}

struct TileView: View {
    let tile: MatchThreeTile
    let size: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    
    var tileColor: Color {
        switch tile.type.color {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "purple": return .purple
        case "orange": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(tileColor.opacity(0.8))
                    .frame(width: size, height: size)
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: size, height: size)
                }
                
                Image(systemName: tile.type.iconName)
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.white)
            }
        }
        .opacity(tile.isMatched ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: tile.isMatched)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.tele2Gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.tele2DarkSecondary)
        .cornerRadius(12)
    }
}

struct GameOverModal: View {
    let isWon: Bool
    let score: Int
    let reward: Int
    let onDismiss: () -> Void
    let onNewGame: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 24) {
                Image(systemName: isWon ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(isWon ? .green : .red)
                
                Text(isWon ? "Победа!" : "Игра окончена")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    Text("Ваш счет: \(score)")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    
                    if isWon {
                        HStack(spacing: 8) {
                            Image(systemName: "bitcoinsign.circle.fill")
                                .foregroundColor(.yellow)
                            Text("Награда: +\(reward) Гигов")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                HStack(spacing: 16) {
                    Button(action: onDismiss) {
                        Text("Закрыть")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.tele2DarkSecondary)
                            .cornerRadius(12)
                    }
                    
                    if isWon {
                        Button(action: onNewGame) {
                            Text("Новая игра")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.tele2Pink)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding(24)
            .background(Color.tele2Dark)
            .cornerRadius(20)
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    MatchThreeGameView()
        .environment(UserStateService())
}
