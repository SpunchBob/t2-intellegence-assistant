//
//  MatchThreeTile.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

enum TileType: Int, CaseIterable, Codable {
    case red = 0
    case blue = 1
    case green = 2
    case yellow = 3
    case purple = 4
    case orange = 5
    
    var iconName: String {
        switch self {
        case .red: return "circle.fill"
        case .blue: return "square.fill"
        case .green: return "triangle.fill"
        case .yellow: return "diamond.fill"
        case .purple: return "hexagon.fill"
        case .orange: return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .red: return "red"
        case .blue: return "blue"
        case .green: return "green"
        case .yellow: return "yellow"
        case .purple: return "purple"
        case .orange: return "orange"
        }
    }
}

struct MatchThreeTile: Identifiable, Equatable {
    let id: UUID
    var type: TileType
    var row: Int
    var col: Int
    var isMatched: Bool = false
    
    init(id: UUID = UUID(), type: TileType, row: Int, col: Int) {
        self.id = id
        self.type = type
        self.row = row
        self.col = col
    }
}
