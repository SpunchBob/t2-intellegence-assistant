//
//  ShopView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import SwiftUI

struct ShopView: View {
    @Environment(UserStateService.self) private var userState
    @State private var viewModel = ShopViewModel()
    @State private var selectedCategory: ShopCategory = .all
    
    var body: some View {
        ZStack {
            Color.tele2Dark
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок
                    headerSection
                    
                    // Карточка Мой Питомец
                    myPetCard
                    
                    // Рекомендации
                    recommendationsSection
                    
                    // Акция дня
                    dealOfTheDaySection
                    
                    // Фильтры
                    filtersSection
                    
                    // Список товаров
                    itemsGrid
                }
                .padding(.bottom, 100) // Отступ для таббара
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.userState = userState
        }
        .alert("Покупка", isPresented: $viewModel.showPurchaseAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.purchaseMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Гиги-шоп")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("Обменивайте Гиги на бонусы")
                .font(.system(size: 16))
                .foregroundColor(.tele2Gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var myPetCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "face.smiling")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Мой Питомец")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Кастомизируй Макс")
                    .font(.system(size: 14))
                    .foregroundColor(.tele2Gray)
            }
            
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundColor(.tele2Pink)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.tele2Pink.opacity(0.3), Color.tele2Pink.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.tele2Pink)
                
                Text("Рекомендации специально для вас")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.recommendedItems) { item in
                        InternetCard(item: item) {
                            viewModel.purchaseItem(item)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var dealOfTheDaySection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Акция дня")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Скидка 30% на 10 ГБ")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    Text("До конца акции: 5ч 12мин")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            Image(systemName: "flame.fill")
                .font(.system(size: 32))
                .foregroundColor(.tele2Pink)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.tele2Pink.opacity(0.3), Color.tele2Pink.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
    
    private var filtersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ShopCategory.allCases, id: \.self) { category in
                    FilterButton(
                        title: category.rawValue,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var itemsGrid: some View {
        let filteredItems = viewModel.items.filter { item in
            if selectedCategory == .all { return true }
            return item.category == selectedCategory
        }
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(filteredItems) { item in
                ShopItemCard(item: item) {
                    viewModel.purchaseItem(item)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct InternetCard: View {
    let item: ShopItem
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 24))
                    .foregroundColor(.tele2Pink)
                
                Spacer()
                
                if item.isRecommended {
                    Text("Для вас")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.tele2Pink)
                        .cornerRadius(12)
                }
            }
            
            Text(item.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            
            HStack(spacing: 8) {
                if let originalPrice = item.originalPrice {
                    Text("\(originalPrice)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .strikethrough()
                }
                
                Text("\(item.price) Гигов")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Button(action: onPurchase) {
                Text("Купить")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.tele2Pink)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .frame(width: 180)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.tele2Pink : Color.tele2DarkSecondary)
                .cornerRadius(20)
        }
    }
}

struct ShopItemCard: View {
    let item: ShopItem
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.system(size: 40))
                .foregroundColor(.tele2Pink)
                .frame(height: 60)
            
            VStack(spacing: 4) {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    if let originalPrice = item.originalPrice {
                        Text("\(originalPrice)")
                            .font(.system(size: 12))
                            .foregroundColor(.tele2Gray)
                            .strikethrough()
                    }
                    
                    Text("\(item.price) Гигов")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Button(action: onPurchase) {
                Text(item.isPurchased ? "Куплено" : "Купить")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(item.isPurchased ? Color.gray : Color.tele2Pink)
                    .cornerRadius(8)
            }
            .disabled(item.isPurchased)
        }
        .padding(12)
        .background(Color.tele2DarkSecondary)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        ShopView()
            .environment(UserStateService())
    }
}
