import SwiftUI

struct ContentView: View {
    @ObservedObject var syncManager = DatabaseSyncManager.shared
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                BrowseView()
                    .tabItem {
                        Label("Explore", systemImage: "safari.fill")
                    }
                
                CollectionView()
                    .tabItem {
                        Label("My Arcade", systemImage: "gamecontroller.fill")
                    }
            }
            .accentColor(Theme.neonPink)
            
            // Floating Auto-Update Status Toast
            if syncManager.isToastPresented, let text = syncManager.toastText {
                HStack(spacing: 10) {
                    if syncManager.isDownloading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.neonPink))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "bolt.badge.checkmark.fill")
                            .foregroundColor(Theme.neonGreen)
                            .neonGlow(color: Theme.neonGreen, radius: 4)
                    }
                    
                    Text(text)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Theme.cardBg.opacity(0.95))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [Theme.neonCyan.opacity(0.8), Theme.neonPink.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.6), radius: 10, y: 5)
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Theme.cardBg)
            
            // Neon cyan for unselected, neon pink for selected
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
            
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.neonPink)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Theme.neonPink)]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Trigger automatic daily background check & update
            syncManager.performDailyAutoCheckAndSync()
        }
        .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

