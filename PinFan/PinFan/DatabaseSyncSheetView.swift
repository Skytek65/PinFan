import SwiftUI

struct DatabaseSyncSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var syncManager = DatabaseSyncManager.shared
    
    @State private var isShowingRepoConfig = false
    @State private var tempOwner = ""
    @State private var tempRepo = ""
    @State private var tempBranch = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                CyberGrid()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title Header
                        VStack(spacing: 4) {
                            Text("DATABASE SYNC")
                                .font(.system(size: 24, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                                .neonGlow(color: Theme.neonCyan, radius: 6)
                            
                            Text("LIVE ARCHIVE UPDATER")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.neonPink)
                                .tracking(2)
                        }
                        .padding(.top, 16)
                        
                        // Status Card
                        Theme.GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("STATUS")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.gray)
                                        
                                        if syncManager.isChecking {
                                            Text("CHECKING FOR UPDATES...")
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                .foregroundColor(Theme.neonGold)
                                        } else if syncManager.isDownloading {
                                            Text("DOWNLOADING & MERGING...")
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                .foregroundColor(Theme.neonPink)
                                        } else if syncManager.updateAvailable {
                                            Text("UPDATE AVAILABLE")
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                .foregroundColor(Theme.neonGreen)
                                        } else {
                                            Text("DATABASE UP TO DATE")
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                .foregroundColor(Theme.neonCyan)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if syncManager.updateAvailable {
                                        Text("NEW")
                                            .font(.system(size: 10, weight: .black, design: .monospaced))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Theme.neonGreen)
                                            .cornerRadius(6)
                                            .neonGlow(color: Theme.neonGreen, radius: 4)
                                    }
                                }
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                // Details
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Last Synced:")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text(formattedLastSyncDate)
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                    }
                                    
                                    if let info = syncManager.remoteVersionInfo {
                                        HStack {
                                            Text("Remote Cabinet Count:")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text("\(info.machineCount) Machines")
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(Theme.neonCyan)
                                        }
                                        
                                        HStack {
                                            Text("Remote Updated At:")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text(info.lastUpdated)
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                }
                                
                                if !syncManager.statusMessage.isEmpty {
                                    Text(syncManager.statusMessage)
                                        .font(.caption2)
                                        .foregroundColor(Theme.neonGold)
                                        .padding(.top, 4)
                                }
                                
                                // Progress Bar if downloading
                                if syncManager.isDownloading {
                                    VStack(alignment: .leading, spacing: 6) {
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white.opacity(0.1))
                                                    .frame(height: 8)
                                                
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [Theme.neonPink, Theme.neonCyan],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(width: geometry.size.width * CGFloat(syncManager.downloadProgress), height: 8)
                                                    .neonGlow(color: Theme.neonPink, radius: 4)
                                            }
                                        }
                                        .frame(height: 8)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            if syncManager.updateAvailable || syncManager.remoteVersionInfo != nil {
                                Button(action: {
                                    Task {
                                        await syncManager.downloadAndApplyUpdate()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.headline)
                                        Text(syncManager.isDownloading ? "DOWNLOADING..." : "INSTALL DATABASE UPDATE")
                                            .font(.system(size: 13, weight: .black, design: .monospaced))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Theme.neonGreen)
                                            .neonGlow(color: Theme.neonGreen, radius: 8)
                                    )
                                }
                                .disabled(syncManager.isDownloading || syncManager.isChecking)
                            }
                            
                            Button(action: {
                                Task {
                                    await syncManager.checkForUpdates()
                                }
                            }) {
                                HStack {
                                    if syncManager.isChecking {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text(syncManager.isChecking ? "CHECKING GITHUB..." : "CHECK FOR UPDATES")
                                        .font(.system(size: 13, weight: .black, design: .monospaced))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.cardBg.opacity(0.6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.neonCyan.opacity(0.5), lineWidth: 1)
                                )
                                .shadow(color: Theme.neonCyan.opacity(0.15), radius: 6)
                            }
                            .disabled(syncManager.isChecking || syncManager.isDownloading)
                        }
                        .padding(.horizontal)
                        
                        // Zero Data Loss Guarantee Card
                        Theme.GlassCard {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                                    .font(.title2)
                                    .foregroundColor(Theme.neonGreen)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("SAFE MERGE GUARANTEE")
                                        .font(.system(size: 11, weight: .black, design: .monospaced))
                                        .foregroundColor(Theme.neonGreen)
                                    
                                    Text("Updating the database preserves all your logged high scores, favorites, owned machines, and custom notes 100%. Only cabinet rankings, prices, and specs will refresh.")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineSpacing(2)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // GitHub Source Configuration (Collapsible)
                        VStack(alignment: .leading, spacing: 10) {
                            Button(action: {
                                withAnimation(.spring()) {
                                    isShowingRepoConfig.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                        .font(.caption)
                                    Text("GITHUB SYNC REPO SETTINGS")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    Spacer()
                                    Image(systemName: isShowingRepoConfig ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                }
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            }
                            
                            if isShowingRepoConfig {
                                Theme.GlassCard {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Configure the GitHub repository where your automated scraper runs:")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("REPO OWNER / USERNAME")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(Theme.neonCyan)
                                            TextField("e.g. your-github-username", text: $tempOwner)
                                                .font(.system(size: 12, design: .monospaced))
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.black.opacity(0.4))
                                                .cornerRadius(6)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("REPOSITORY NAME")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(Theme.neonCyan)
                                            TextField("e.g. splendid-faraday", text: $tempRepo)
                                                .font(.system(size: 12, design: .monospaced))
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.black.opacity(0.4))
                                                .cornerRadius(6)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("BRANCH")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(Theme.neonCyan)
                                            TextField("e.g. main", text: $tempBranch)
                                                .font(.system(size: 12, design: .monospaced))
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.black.opacity(0.4))
                                                .cornerRadius(6)
                                        }
                                        
                                        Button(action: {
                                            syncManager.repoOwner = tempOwner.trimmingCharacters(in: .whitespacesAndNewlines)
                                            syncManager.repoName = tempRepo.trimmingCharacters(in: .whitespacesAndNewlines)
                                            syncManager.branch = tempBranch.trimmingCharacters(in: .whitespacesAndNewlines)
                                            withAnimation {
                                                isShowingRepoConfig = false
                                            }
                                        }) {
                                            Text("SAVE CONFIGURATION")
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(.black)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(Theme.neonCyan)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.neonPink)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
            }
            .onAppear {
                tempOwner = syncManager.repoOwner
                tempRepo = syncManager.repoName
                tempBranch = syncManager.branch
                
                // Auto check on opening if never checked before
                if syncManager.remoteVersionInfo == nil && !syncManager.isChecking {
                    Task {
                        await syncManager.checkForUpdates()
                    }
                }
            }
        }
        .accentColor(Theme.neonPink)
    }
    
    private var formattedLastSyncDate: String {
        guard let date = syncManager.lastSyncDate else { return "Never" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
