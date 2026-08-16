import SwiftUI

struct CollectionView: View {
    @State private var machines: [PinballMachine] = []
    @State private var selectedTab = 0 // 0 = Collection, 1 = Wishlist
    @State private var isShowingSyncSheet = false
    @ObservedObject var syncManager = DatabaseSyncManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                CyberGrid()
                
                VStack(spacing: 0) {
                    // Custom Arcade Segmented Control
                    Picker("Tab Selection", selection: $selectedTab) {
                        Text("MY COLLECTION").tag(0)
                        Text("WISHLIST").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .onChange(of: selectedTab) { _ in
                        loadCollectionData()
                    }
                    
                    if machines.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: selectedTab == 0 ? "archivebox" : "heart.text.square")
                                .font(.system(size: 64))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text(selectedTab == 0 ? "YOUR COLLECTION IS EMPTY" : "YOUR WISHLIST IS EMPTY")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundColor(.gray)
                                .tracking(1)
                            
                            Text(selectedTab == 0 ? "Explore cabinets to mark ones you own!" : "Add pinball machines you want to play to your wishlist!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(machines) { machine in
                                NavigationLink(destination: MachineDetailView(machineId: machine.machineKey)) {
                                    BrowseRow(machine: machine)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("MY ARCADE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(selectedTab == 0 ? "MY COLLECTION" : "MY WISHLIST")
                        .font(.system(.headline, design: .monospaced))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .neonGlow(color: selectedTab == 0 ? Theme.neonCyan : Theme.neonPink, radius: 4)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingSyncSheet = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "arrow.triangle.2.circlepath.circle")
                                .font(.title3)
                                .foregroundColor(syncManager.updateAvailable ? Theme.neonGreen : Theme.neonCyan)
                                .neonGlow(color: syncManager.updateAvailable ? Theme.neonGreen : Theme.neonCyan, radius: 4)
                            
                            if syncManager.updateAvailable {
                                Circle()
                                    .fill(Theme.neonPink)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingSyncSheet) {
                DatabaseSyncSheetView()
            }
            .onAppear(perform: loadCollectionData)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DatabaseDidUpdate"))) { _ in
                loadCollectionData()
            }
        }
        .accentColor(Theme.neonPink)
    }
    
    private func loadCollectionData() {
        let onlyFavorites = selectedTab == 1
        machines = DatabaseManager.shared.getCollection(onlyFavorites: onlyFavorites)
    }
}
