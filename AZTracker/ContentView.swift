//
//  ContentView.swift
//  AZTracker
//
//  Created by Ahmed Zahran on 4/6/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            WeeklyView()
                .tabItem {
                    Label("Weekly", systemImage: "calendar")
                }
            
            WorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "dumbbell.fill")
                }
            
            MealPlanView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
            
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .accentColor(.red) // Durrah-inspired red accent color
        .preferredColorScheme(.dark) // Default to dark mode
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
}
