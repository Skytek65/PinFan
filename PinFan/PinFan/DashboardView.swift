import SwiftUI

struct DashboardView: View {
    @State private var featuredMachines: [PinballMachine] = []
    @State private var collectionPreview: [PinballMachine] = []
    @State private var totalCount: Int = 0
    @State private var averageRating: Double = 0.0
    @State private var randomMachine: PinballMachine?
    @State private var isShowingRandomDetail = false
    @State private var triviaIndex = 0
    @State private var heroMachine: PinballMachine? = nil
    
    let triviaFacts = [
        "The Addams Family (Bally, 1992) is the best-selling pinball machine of all time, with 20,277 units manufactured.",
        "Banzai Run (Williams, 1988) was Pat Lawlor's first playfield design. It features a unique vertical playfield in the backbox.",
        "Williams WPC (Williams Pinball Controller) boardset was the industry standard for 1990s solid-state machines, starting with FunHouse.",
        "Pinball was banned in major US cities (like New York, Chicago, and Los Angeles) for over 30 years as it was considered a game of chance and gambling.",
        "In 1976, Roger Sharpe testified before a New York City council to prove pinball is a game of skill, calling his shot on the playing field to lift the ban.",
        "Gottlieb's Humpty Dumpty (1947) was the first pinball machine to feature player-controlled flippers.",
        "The term 'Sling-shot' refers to the triangular-shaped kickers located above the flippers that bounce the ball away rapidly.",
        "Medieval Madness (Williams, 1997) features an interactive castle that explodes and collapses physically when hit by the ball."
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                CyberGrid()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Modern High-Tech Header Row
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SYS_ACTIVE // PLAYER_01")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.neonCyan)
                                Text("PIN-FAN")
                                    .font(.system(size: 28, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            
                            // Compact Stats Container
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(totalCount) CABINETS")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.neonPink)
                                Text(String(format: "%.2f ★ AVG", averageRating))
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.neonGold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Theme.cardBg.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // Today's Featured Cabinet Hero Banner
                        if let hero = heroMachine {
                            NavigationLink(destination: MachineDetailView(machineId: hero.machineKey)) {
                                ZStack(alignment: .bottom) {
                                    if let imgPath = hero.imageRelPath, let url = URL(string: imgPath) {
                                        AsyncImage(url: url) { img in
                                            img
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            ZStack {
                                                Theme.cardBg
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.neonPink))
                                            }
                                        }
                                        .frame(height: 220)
                                        .clipped()
                                    } else {
                                        ZStack {
                                            Theme.cardBg
                                            Image(systemName: "gamecontroller.fill")
                                                .font(.largeTitle)
                                                .foregroundColor(.gray)
                                        }
                                        .frame(height: 220)
                                    }
                                    
                                    LinearGradient(
                                        gradient: Gradient(colors: [.clear, .black.opacity(0.85)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("TODAY'S FEATURED CABINET")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(Theme.neonGold)
                                            .tracking(2)
                                        
                                        HStack(alignment: .bottom) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(hero.displayName)
                                                    .font(.title2)
                                                    .fontWeight(.black)
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Text("\(hero.manufName ?? "Unknown") • \(hero.yearString)")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 4) {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(Theme.neonGold)
                                                    .font(.caption)
                                                Text(String(format: "%.2f", hero.machineRating ?? 0.0))
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(8)
                                        }
                                    }
                                    .padding(16)
                                }
                                .frame(height: 220)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(LinearGradient(colors: [Theme.neonCyan.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                                )
                                .shadow(color: Theme.neonCyan.opacity(0.15), radius: 10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                        
                        // Symmetrical Action Row
                        HStack(spacing: 16) {
                            Button(action: triggerRandomPick) {
                                HStack {
                                    Image(systemName: "dice.fill")
                                        .foregroundColor(Theme.neonPink)
                                    Text("ARCADE ROULETTE")
                                        .font(.system(size: 11, weight: .black, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.cardBg.opacity(0.4))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.neonPink.opacity(0.4), lineWidth: 1)
                                )
                                .shadow(color: Theme.neonPink.opacity(0.1), radius: 6)
                            }
                            
                            Button(action: nextTriviaFact) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(Theme.neonGold)
                                    Text("NEXT TRIVIA")
                                        .font(.system(size: 11, weight: .black, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.cardBg.opacity(0.4))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.neonGold.opacity(0.4), lineWidth: 1)
                                )
                                .shadow(color: Theme.neonGold.opacity(0.1), radius: 6)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Pinball Trivia Box Section
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(Theme.neonGold)
                                    .font(.caption)
                                Text("DID YOU KNOW?")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.neonGold)
                                    .tracking(1)
                                Spacer()
                            }
                            Text(triviaFacts[triviaIndex])
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.85))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .animation(.easeInOut, value: triviaIndex)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.cardBg.opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .overlay(
                            HStack {
                                Rectangle()
                                    .fill(Theme.neonGold)
                                    .frame(width: 3)
                                Spacer()
                            }
                            .cornerRadius(12)
                            .clipped()
                        )
                        .padding(.horizontal)
                        
                        // My Arcade Preview Section (Favorited/Owned games)
                        if !collectionPreview.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("MY CABINETS")
                                    .font(.system(.title3, design: .monospaced))
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(collectionPreview) { machine in
                                            NavigationLink(destination: MachineDetailView(machineId: machine.machineKey)) {
                                                FeaturedCard(machine: machine)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Featured Machines Header
                        HStack {
                            Text("TOP CABINETS")
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            Spacer()
                            Text("RANKED")
                                .font(.caption)
                                .foregroundColor(Theme.neonCyan)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Featured Machines Horizontal Scroll
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(featuredMachines) { machine in
                                    NavigationLink(destination: MachineDetailView(machineId: machine.machineKey)) {
                                        FeaturedCard(machine: machine)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingRandomDetail) {
                if let machine = randomMachine {
                    NavigationView {
                        MachineDetailView(machineId: machine.machineKey)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("Dismiss") {
                                        isShowingRandomDetail = false
                                    }
                                    .foregroundColor(Theme.neonPink)
                                }
                            }
                    }
                    .accentColor(Theme.neonPink)
                }
            }
            .onAppear(perform: loadDashboardData)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DatabaseDidUpdate"))) { _ in
                loadDashboardData()
            }
        }
    }
    
    private func loadDashboardData() {
        let stats = DatabaseManager.shared.getStats()
        totalCount = stats.totalCount
        averageRating = stats.averageRating
        
        featuredMachines = DatabaseManager.shared.getFeaturedMachines()
        heroMachine = DatabaseManager.shared.getRandomTop100Machine()
        
        // Merge owned and favorites for home preview list
        let owned = DatabaseManager.shared.getCollection(onlyFavorites: false)
        let favorites = DatabaseManager.shared.getCollection(onlyFavorites: true)
        
        // Combine lists and remove duplicates
        var combined = owned
        for fav in favorites {
            if !combined.contains(where: { $0.machineKey == fav.machineKey }) {
                combined.append(fav)
            }
        }
        collectionPreview = combined.sorted(by: { $0.machineName < $1.machineName })
    }
    
    private func triggerRandomPick() {
        if let random = DatabaseManager.shared.getRandomMachine() {
            randomMachine = random
            isShowingRandomDetail = true
        }
    }
    
    private func nextTriviaFact() {
        triviaIndex = (triviaIndex + 1) % triviaFacts.count
    }
}

// Subview: Featured Machine Card
struct FeaturedCard: View {
    let machine: PinballMachine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Async Image Loader
            if let imgPath = machine.imageRelPath, let url = URL(string: imgPath) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Theme.cardBg
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.neonPink))
                    }
                }
                .frame(width: 180, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    Theme.cardBg
                    Image(systemName: "gamecontroller.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
                .frame(width: 180, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(machine.displayName)
                    .font(.system(.subheadline, design: .default))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text(machine.manufName ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(machine.yearString)
                        .font(.caption)
                        .foregroundColor(Theme.neonCyan)
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text(machine.rankString)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Theme.neonPink)
                        .fontWeight(.black)
                    Spacer()
                    Text(machine.ratingString)
                        .font(.caption)
                        .foregroundColor(Theme.neonGold)
                        .fontWeight(.bold)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Theme.cardBg.opacity(0.8))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.neonPurple.opacity(0.3), lineWidth: 1)
        )
        .frame(width: 196)
    }
}
