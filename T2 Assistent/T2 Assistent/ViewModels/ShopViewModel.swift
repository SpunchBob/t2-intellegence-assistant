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
    var dealOfTheDay: ShopItem?
    var showPurchaseAlert = false
    var purchaseMessage = ""
    var isLoading: Bool = false
    var errorMessage: String?
    
    var userState: UserStateService?
    
    private let shopService = ShopService.shared
    
    init() {
        loadItems()
    }
    
    func loadItems() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Загружаем все данные параллельно
                async let itemsTask = shopService.loadItems()
                async let recommendedTask = shopService.loadRecommendedItems()
                async let dealTask = shopService.loadDealOfTheDay()
                
                let (loadedItems, loadedRecommended, loadedDeal) = try await (itemsTask, recommendedTask, dealTask)
                
                await MainActor.run {
                    self.items = loadedItems
                    self.recommendedItems = loadedRecommended
                    self.dealOfTheDay = loadedDeal
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Ошибка загрузки товаров: \(error.localizedDescription)"
                    self.isLoading = false
                    
                    // Загружаем локальные данные при ошибке
                    self.loadLocalItems()
                }
                print("Error loading shop items: \(error)")
            }
        }
    }
    
    private func loadLocalItems() {
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
        
        // Покупаем через сервис
        Task {
            do {
                let result = try await shopService.purchaseItem(item)
                
                await MainActor.run {
                    if result.success {
                        // Списываем койны локально
                        if userState.spendCoins(item.price) {
                            // Обновляем статус товара
                            if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                                self.items[index].isPurchased = true
                            }
                            
                            // Обновляем баланс если сервер вернул новый
                            if let newBalance = result.newBalance {
                                userState.coin.amount = newBalance
                            }
                            
                            self.purchaseMessage = result.message
                            self.showPurchaseAlert = true
                        }
                    } else {
                        self.purchaseMessage = result.message
                        self.showPurchaseAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.purchaseMessage = "Ошибка покупки: \(error.localizedDescription)"
                    self.showPurchaseAlert = true
                }
                print("Error purchasing item: \(error)")
            }
        }
    }
}
