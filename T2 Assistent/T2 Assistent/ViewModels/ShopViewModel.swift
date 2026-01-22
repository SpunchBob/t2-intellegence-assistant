//
//  ShopViewModel.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

@Observable
@MainActor
class ShopViewModel {
    var items: [ShopItem] = []
    var recommendedItems: [ShopItem] = []
    var showPurchaseAlert = false
    var purchaseMessage = ""
    
    var userState: UserStateService?
    
    init() {
        loadItems()
    }
    
    private func loadItems() {
        // Рекомендуемые товары (интернет)
        recommendedItems = [
            ShopItem(
                name: "10 ГБ интернета",
                description: "",
                price: 105,
                originalPrice: 150,
                iconName: "antenna.radiowaves.left.and.right",
                category: .gigs,
                isRecommended: true
            ),
            ShopItem(
                name: "50 ГБ интернета",
                description: "",
                price: 600,
                iconName: "antenna.radiowaves.left.and.right",
                category: .gigs,
                isRecommended: true
            )
        ]
        
        // Все товары
        items = [
            ShopItem(
                name: "10 ГБ интернета",
                description: "Дополнительный интернет",
                price: 105,
                originalPrice: 150,
                iconName: "antenna.radiowaves.left.and.right",
                category: .gigs,
                isRecommended: true,
                isDealOfTheDay: true
            ),
            ShopItem(
                name: "50 ГБ интернета",
                description: "Большой пакет интернета",
                price: 600,
                iconName: "antenna.radiowaves.left.and.right",
                category: .gigs,
                isRecommended: true
            ),
            ShopItem(
                name: "100 минут",
                description: "Звонки на все номера",
                price: 200,
                iconName: "phone.fill",
                category: .minutes
            ),
            ShopItem(
                name: "Скидка 10%",
                description: "Скидка на следующий платеж",
                price: 500,
                iconName: "percent",
                category: .discounts
            ),
            ShopItem(
                name: "Скидка 20%",
                description: "Большая скидка на тариф",
                price: 800,
                iconName: "tag.fill",
                category: .discounts
            ),
            ShopItem(
                name: "Премиум статус",
                description: "Особые привилегии на месяц",
                price: 1000,
                iconName: "star.fill",
                category: .exclusives
            ),
            ShopItem(
                name: "Бесплатные СМС",
                description: "100 СМС в подарок",
                price: 200,
                iconName: "message.fill",
                category: .gigs
            ),
            ShopItem(
                name: "200 минут",
                description: "Удвоенные минуты",
                price: 350,
                iconName: "phone.fill",
                category: .minutes
            )
        ]
    }
    
    func purchaseItem(_ item: ShopItem) {
        guard !item.isPurchased else { return }
        guard let userState = userState else { return }
        
        let currentCoins = userState.coin.amount
        guard currentCoins >= item.price else {
            purchaseMessage = "Недостаточно койнов. Нужно \(item.price), у вас \(currentCoins)"
            showPurchaseAlert = true
            return
        }
        
        if userState.spendCoins(item.price) {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index].isPurchased = true
            }
            purchaseMessage = "Вы успешно купили \(item.name)!"
            showPurchaseAlert = true
        }
    }
}
