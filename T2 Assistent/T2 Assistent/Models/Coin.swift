//
//  Coin.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

struct Coin: Identifiable, Codable {
    let id: UUID
    var amount: Int
    
    init(id: UUID = UUID(), amount: Int = 0) {
        self.id = id
        self.amount = amount
    }
}
