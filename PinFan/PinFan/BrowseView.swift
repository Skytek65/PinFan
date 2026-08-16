import SwiftUI

struct BrowseView: View {
    @State private var machines: [PinballMachine] = []
    @State private var searchText = ""
    @State private var selectedManufacturer = ""
    @State private var selectedReleaseType = ""
    @State private var selectedDecade = ""
    @State private var selectedDisplayType = ""
    
    @State private var page = 1
    @State private var isLastPage = false
    @State private var isLoading = false
    @State private var isShowingFilter = false
    @State private var manufacturers: [String] = []
    
    let releaseTypes = ["commercial", "prototype", "homebrew", "custom"]
    let decades = ["2020s", "2010s", "2000s", "1990s", "1980s", "1970s", "1960s", "1950s", "1930s-40s"]
    let displayTypes = ["LCD", "DMD", "Alphanumeric", "Reels"]
    
    var body: some View {
        NavigationView {
            ZStack {
                CyberGrid()
                
                VStack(spacing: 0) {
                    // Search & Filter Header
                    HStack(spacing: 12) {
                        // Cyberpunk styled search input
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Theme.neonCyan)
                            TextField("Search Cabinets...", text: $searchText)
                                .foregroundColor(.white)
                                .onChange(of: searchText) { _ in
                                    resetSearch()
                                }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Theme.cardBg.opacity(0.8))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.neonCyan.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Filter trigger button
                        Button(action: { isShowingFilter = true }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(hasActiveFilters ? Theme.neonPink : Theme.cardBg.opacity(0.8))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(hasActiveFilters ? Theme.neonPink : Theme.neonPurple.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 8)
                    
                    // Legend bar explaining SS and EM
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Text("SS")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.neonPink)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Theme.neonPink.opacity(0.15))
                                .cornerRadius(3)
                            Text("Solid State (Digital)")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.15))
                            .font(.system(size: 9))
                        
                        HStack(spacing: 4) {
                            Text("EM")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.neonCyan)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Theme.neonCyan.opacity(0.15))
                                .cornerRadius(3)
                            Text("Electro-Mechanical (Analog)")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.02))
                    .overlay(
                        VStack {
                            Divider().background(Color.white.opacity(0.08))
                            Spacer()
                            Divider().background(Color.white.opacity(0.08))
                        }
                    )
                    
                    // Main list
                    if machines.isEmpty && !isLoading {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "gamecontroller")
                                .font(.system(size: 64))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("NO CABINETS FOUND")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundColor(.gray)
                                .tracking(1)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(machines) { machine in
                                NavigationLink(destination: MachineDetailView(machineId: machine.machineKey)) {
                                    BrowseRow(machine: machine)
                                        .onAppear {
                                            // Trigger pagination when reaching last item
                                            if machine.machineKey == machines.last?.machineKey {
                                                loadNextPage()
                                            }
                                        }
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                            
                            if isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.neonPink))
                                    Spacer()
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("EXPLORE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EXPLORE CABINETS")
                        .font(.system(.headline, design: .monospaced))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .neonGlow(color: Theme.neonPink, radius: 4)
                }
            }
            .sheet(isPresented: $isShowingFilter) {
                FilterSheetView(
                    selectedManufacturer: $selectedManufacturer,
                    selectedReleaseType: $selectedReleaseType,
                    selectedDecade: $selectedDecade,
                    selectedDisplayType: $selectedDisplayType,
                    manufacturers: manufacturers,
                    releaseTypes: releaseTypes,
                    decades: decades,
                    displayTypes: displayTypes,
                    onApply: {
                        resetSearch()
                        isShowingFilter = false
                    },
                    onReset: {
                        selectedManufacturer = ""
                        selectedReleaseType = ""
                        selectedDecade = ""
                        selectedDisplayType = ""
                        resetSearch()
                        isShowingFilter = false
                    }
                )
            }
            .onAppear {
                if machines.isEmpty {
                    loadInitialData()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DatabaseDidUpdate"))) { _ in
                resetSearch()
            }
        }
        .accentColor(Theme.neonPink)
    }
    
    private var hasActiveFilters: Bool {
        !selectedManufacturer.isEmpty || !selectedReleaseType.isEmpty || !selectedDecade.isEmpty || !selectedDisplayType.isEmpty
    }
    
    private func loadInitialData() {
        manufacturers = DatabaseManager.shared.getUniqueManufacturers()
        loadNextPage()
    }
    
    private func resetSearch() {
        page = 1
        isLastPage = false
        machines = []
        loadNextPage()
    }
    
    private func loadNextPage() {
        guard !isLoading && !isLastPage else { return }
        
        isLoading = true
        
        // Run database fetch asynchronously to keep UI fluid
        DispatchQueue.global(qos: .userInitiated).async {
            let fetched = DatabaseManager.shared.fetchMachines(
                queryText: self.searchText,
                manufacturer: self.selectedManufacturer.isEmpty ? nil : self.selectedManufacturer,
                releaseType: self.selectedReleaseType.isEmpty ? nil : self.selectedReleaseType,
                decade: self.selectedDecade.isEmpty ? nil : self.selectedDecade,
                displayType: self.selectedDisplayType.isEmpty ? nil : self.selectedDisplayType,
                page: self.page
            )
            
            DispatchQueue.main.async {
                self.isLoading = false
                if fetched.isEmpty {
                    self.isLastPage = true
                } else {
                    self.machines.append(contentsOf: fetched)
                    self.page += 1
                }
            }
        }
    }
}

// Subview: Filter Sheet View with added pickers
struct FilterSheetView: View {
    @Binding var selectedManufacturer: String
    @Binding var selectedReleaseType: String
    @Binding var selectedDecade: String
    @Binding var selectedDisplayType: String
    
    let manufacturers: [String]
    let releaseTypes: [String]
    let decades: [String]
    let displayTypes: [String]
    
    var onApply: () -> Void
    var onReset: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.arcadeBlack.ignoresSafeArea()
                
                Form {
                    Section(header: Text("MANUFACTURER").foregroundColor(Theme.neonCyan)) {
                        Picker("Select Manufacturer", selection: $selectedManufacturer) {
                            Text("All Manufacturers").tag("")
                            ForEach(manufacturers, id: \.self) { manuf in
                                Text(manuf).tag(manuf)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .listRowBackground(Theme.cardBg)
                    
                    Section(header: Text("RELEASE TYPE").foregroundColor(Theme.neonCyan)) {
                        Picker("Select Release Type", selection: $selectedReleaseType) {
                            Text("All Release Types").tag("")
                            ForEach(releaseTypes, id: \.self) { type in
                                Text(type.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .listRowBackground(Theme.cardBg)
                    
                    Section(header: Text("DECADE").foregroundColor(Theme.neonCyan)) {
                        Picker("Select Decade", selection: $selectedDecade) {
                            Text("All Decades").tag("")
                            ForEach(decades, id: \.self) { dec in
                                Text(dec).tag(dec)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .listRowBackground(Theme.cardBg)
                    
                    Section(header: Text("DISPLAY SYSTEM").foregroundColor(Theme.neonCyan)) {
                        Picker("Select Display Type", selection: $selectedDisplayType) {
                            Text("All Displays").tag("")
                            ForEach(displayTypes, id: \.self) { disp in
                                Text(disp).tag(disp)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .listRowBackground(Theme.cardBg)
                }
                .background(Color.clear)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("FILTERS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset", action: onReset)
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply", action: onApply)
                        .foregroundColor(Theme.neonPink)
                        .fontWeight(.bold)
                }
            }
        }
        .accentColor(Theme.neonPink)
    }
}

// Subview: List Row item
struct BrowseRow: View {
    let machine: PinballMachine
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail Image loader
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
                .frame(width: 80, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    Theme.cardBg
                    Image(systemName: "gamecontroller.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(width: 80, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Text contents
            VStack(alignment: .leading, spacing: 4) {
                Text(machine.baseName ?? machine.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(machine.manufName ?? "Unknown")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text(machine.yearString)
                        .font(.subheadline)
                        .foregroundColor(Theme.neonCyan)
                        .fontWeight(.bold)
                }
                
                if machine.editions.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(machine.editions.prefix(4)) { ed in
                                Text(ed.editionName.uppercased())
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.neonCyan)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Theme.neonCyan.opacity(0.12))
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Theme.neonCyan.opacity(0.2), lineWidth: 0.5)
                                    )
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            if machine.editions.count > 4 {
                                Text("+\(machine.editions.count - 4)")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Rating and Rank summary
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Theme.neonGold)
                        .font(.caption)
                    Text(machine.ratingString.replacingOccurrences(of: " ★", with: ""))
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
                
                Text(machine.rankString)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.neonPink)
                    .fontWeight(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.neonPink.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Theme.cardBg.opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.neonPurple.opacity(0.2), lineWidth: 1)
        )
    }
}
