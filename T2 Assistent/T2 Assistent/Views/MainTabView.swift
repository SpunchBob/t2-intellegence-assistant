//
//  MainTabView.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @State private var userState = UserStateService()
    @State private var topBarManager = TopBarManager.shared
    
    var body: some View {
        ZStack {
            // Таббар с тремя экранами
            TabView {
                NavigationStack {
                    ZStack {
                        Color.tele2Dark.ignoresSafeArea()
                        ChatView()
                           
                    }
                    .onAppear {
                        topBarManager.show()
                    }
                }
                .tabItem {
                    Label("Помощник", systemImage: "message.fill")
                }
                .toolbarBackground(Color.tele2Dark, for: .tabBar)
                
                NavigationStack {
                    ZStack {
                        Color.tele2Dark.ignoresSafeArea()
                        ShopView()
                            
                    }
                    .onAppear {
                        topBarManager.show()
                    }
                }
                .tabItem {
                    Label("Магазин", systemImage: "cart.fill")
                }
                
                NavigationStack {
                    ZStack {
                        Color.tele2Dark.ignoresSafeArea()
                        CoinsView()
                            
                        
                    }
                    .onAppear {
                        topBarManager.show()
                    }
                }
                .tabItem {
                    Label("Мои койны", systemImage: "gamecontroller.fill")
                }
            }
            .padding(.top, TopBarManager.shared.isVisible ? 60 : 0)
            .onAppear {
                // Настройка внешнего вида таббара
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1.0)
                
                // Нормальное состояние
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
                
                // Выбранное состояние
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0)
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0)]
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            
            // Верхний бар поверх всего
            VStack {
                TopBarView()
                    .environment(userState)
                Spacer()
            }
            
            // Система туториалов - самый передний слой
            TutorialOverlayView()
        }
        .environment(userState)
    }
}


#Preview {
    MainTabView()
}
