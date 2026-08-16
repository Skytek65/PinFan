import SwiftUI

enum DragDirection {
    case none, horizontal, vertical
}

struct GalleryImage: Identifiable, Hashable {
    let id = UUID()
    let thumbnailURL: String
    let highResURL: String
}

struct MachineDetailView: View {
    let machineId: Int
    
    @State private var machine: PinballMachine?
    @State private var galleryImages: [GalleryImage] = []
    @State private var isGalleryLoading = false
    @State private var isShowingToast = false
    @State private var toastMessage = ""
    @State private var selectedFullScreenImage: GalleryImage?
    @State private var dragOffset: CGSize = .zero
    @State private var highScores: [HighScore] = []
    @State private var isShowingLogScore = false
    @State private var selectedScoreToEdit: HighScore? = nil
    @State private var currentMachineId: Int?
    @State private var dragDirection: DragDirection = .none
    @State private var zoomScale: CGFloat = 1.0
    @State private var currentZoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var currentPanOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            CyberGrid()
            
            if let machine = machine {
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Header (Single Main Image of the cabinet)
                        ZStack(alignment: .bottomLeading) {
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
                                .frame(width: UIScreen.main.bounds.width - 32, height: 250)
                                .clipped()
                            } else {
                                ZStack {
                                    Theme.cardBg
                                    Image(systemName: "gamecontroller.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.gray)
                                }
                                .frame(width: UIScreen.main.bounds.width - 32, height: 250)
                            }
                            
                            // Bottom Gradient Overlay for text readability
                            LinearGradient(
                                colors: [Color.black.opacity(0.85), Color.black.opacity(0)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 110)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(machine.rankString)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.neonPink)
                                    .cornerRadius(4)
                                
                                Text(machine.displayName)
                                    .font(.system(.title2, design: .default))
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                                    .neonGlow(color: .black, radius: 2)
                            }
                            .padding()
                        }
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.neonCyan.opacity(0.4), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Editions Selection Buttons
                        if machine.editions.count > 1 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("AVAILABLE EDITIONS")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.neonCyan)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(machine.editions) { ed in
                                            Button(action: {
                                                withAnimation(.spring()) {
                                                    currentMachineId = ed.machineKey
                                                    loadMachineDetails()
                                                }
                                            }) {
                                                Text(ed.editionName.uppercased())
                                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                    .foregroundColor((currentMachineId ?? machine.machineKey) == ed.machineKey ? .white : .gray)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        (currentMachineId ?? machine.machineKey) == ed.machineKey ?
                                                        RoundedRectangle(cornerRadius: 8).fill(Theme.neonCyan.opacity(0.25)) :
                                                        RoundedRectangle(cornerRadius: 8).fill(Theme.cardBg.opacity(0.4))
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke((currentMachineId ?? machine.machineKey) == ed.machineKey ? Theme.neonCyan : Color.clear, lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Owned & Favorite Action Controls
                        HStack(spacing: 16) {
                            // Owned Toggle
                            Button(action: toggleOwned) {
                                HStack {
                                    Image(systemName: machine.isOwned ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(machine.isOwned ? Theme.neonGreen : .gray)
                                    Text(machine.isOwned ? "OWNED" : "OWN MACHINE")
                                        .font(.caption)
                                        .fontWeight(.black)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.GlassCard { EmptyView() })
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(machine.isOwned ? Theme.neonGreen : Color.clear, lineWidth: 1.5)
                                )
                            }
                            
                            // Wishlist/Favorite Toggle
                            Button(action: toggleFavorite) {
                                HStack {
                                    Image(systemName: machine.isFavorite ? "heart.fill" : "heart")
                                        .foregroundColor(machine.isFavorite ? Theme.neonPink : .gray)
                                    Text(machine.isFavorite ? "WISHLISTED" : "ADD TO WISHLIST")
                                        .font(.caption)
                                        .fontWeight(.black)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.GlassCard { EmptyView() })
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(machine.isFavorite ? Theme.neonPink : Color.clear, lineWidth: 1.5)
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Specifications Grid Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TECHNICAL SPECS")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundColor(Theme.neonCyan)
                                .fontWeight(.black)
                                .padding(.horizontal)
                            
                            Theme.GlassCard {
                                GridView(machine: machine)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Playfield & Cabinet Gallery Section (Below Technical Specs)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PLAYFIELD & CABINET GALLERY")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundColor(Theme.neonGold)
                                .fontWeight(.black)
                                .padding(.horizontal)
                            
                            if isGalleryLoading {
                                Theme.GlassCard {
                                    HStack {
                                        Spacer()
                                        ProgressView("LOADING GALLERY...")
                                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.neonPink))
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 24)
                                }
                                .padding(.horizontal)
                            } else if !galleryImages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(galleryImages, id: \.self) { img in
                                            if let url = URL(string: img.thumbnailURL) {
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
                                                .frame(width: 200, height: 200)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Theme.neonCyan.opacity(0.3), lineWidth: 1)
                                                )
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    withAnimation(.spring()) {
                                                        selectedFullScreenImage = img
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } else {
                                Theme.GlassCard {
                                    Text("No extra photos available for this cabinet.")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 16)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Arcade Features, Slogans, Comments Section
                        VStack(spacing: 20) {
                            if let toys = machine.machineToys, !toys.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                DetailSection(title: "SPECIAL FEATURES & TOYS", content: toys, color: Theme.neonPurple)
                            }
                            
                            if let slogans = machine.machineSlogans, !slogans.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                DetailSection(title: "SLOGANS & QUOTES", content: slogans, color: Theme.neonGold)
                            }
                            
                            if let comments = machine.machineComments, !comments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                DetailSection(title: "HISTORY & COMMENTS", content: comments, color: Theme.neonCyan)
                            }
                        }
                        
                        // High Scores Board Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("HIGH SCORES BOARD")
                                    .font(.system(.headline, design: .monospaced))
                                    .foregroundColor(Theme.neonGold)
                                    .fontWeight(.black)
                                Spacer()
                                Button(action: { isShowingLogScore = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("LOG SCORE")
                                    }
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.neonCyan)
                                }
                            }
                            .padding(.horizontal)
                            
                            Theme.GlassCard {
                                if highScores.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "gamecontroller.fill")
                                            .font(.title)
                                            .foregroundColor(.gray.opacity(0.5))
                                        Text("NO HIGH SCORES YET")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(.gray)
                                        Text("Be the first to log a record!")
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(highScores) { score in
                                            Button(action: { selectedScoreToEdit = score }) {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    HStack {
                                                        Text(score.playerInitials)
                                                            .font(.system(.headline, design: .monospaced))
                                                            .foregroundColor(Theme.neonCyan)
                                                            .frame(width: 50, alignment: .leading)
                                                        
                                                        Text(score.formattedScore)
                                                            .font(.system(.headline, design: .monospaced))
                                                            .fontWeight(.black)
                                                            .foregroundColor(.white)
                                                        
                                                        Spacer()
                                                        
                                                        Text(score.scoreDate)
                                                            .font(.system(size: 11, design: .monospaced))
                                                            .foregroundColor(.gray)
                                                    }
                                                    
                                                    if !score.notes.isEmpty {
                                                        Text(score.notes)
                                                            .font(.system(size: 11))
                                                            .foregroundColor(.gray.opacity(0.9))
                                                            .padding(.leading, 50)
                                                    }
                                                }
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            if score.id != highScores.last?.id {
                                                Divider().background(Color.gray.opacity(0.3))
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 32)
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.neonPink))
            }
            
            // Toast Notification
            if isShowingToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Capsule().fill(Theme.cardBg))
                        .overlay(Capsule().stroke(Theme.neonCyan, lineWidth: 1))
                        .shadow(color: Theme.neonCyan.opacity(0.4), radius: 6)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: isShowingToast)
            }
            
            // Fullscreen Lightbox Overlay View
            if selectedFullScreenImage != nil {
                ZStack {
                    Color.black
                        .opacity(Double(max(0.2, 1.0 - (dragOffset.height / 400.0))))
                        .ignoresSafeArea()
                    
                    TabView(selection: $selectedFullScreenImage) {
                        ForEach(galleryImages, id: \.self) { img in
                            if let url = URL(string: img.highResURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .padding(16)
                                        .scaleEffect(zoomScale)
                                        .offset(panOffset)
                                        .gesture(
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    zoomScale = max(1.0, currentZoomScale * value)
                                                }
                                                .onEnded { value in
                                                    currentZoomScale = min(5.0, max(1.0, currentZoomScale * value))
                                                    zoomScale = currentZoomScale
                                                    if zoomScale <= 1.0 {
                                                        withAnimation(.spring()) {
                                                            panOffset = .zero
                                                            currentPanOffset = .zero
                                                        }
                                                    }
                                                }
                                        )
                                        .gesture(
                                            zoomScale > 1.0 ?
                                            DragGesture()
                                                .onChanged { value in
                                                    panOffset = CGSize(
                                                        width: currentPanOffset.width + value.translation.width,
                                                        height: currentPanOffset.height + value.translation.height
                                                    )
                                                }
                                                .onEnded { value in
                                                    let maxW = (zoomScale - 1.0) * 150.0
                                                    let maxH = (zoomScale - 1.0) * 200.0
                                                    let clampedW = min(maxW, max(-maxW, currentPanOffset.width + value.translation.width))
                                                    let clampedH = min(maxH, max(-maxH, currentPanOffset.height + value.translation.height))
                                                    
                                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                        currentPanOffset = CGSize(width: clampedW, height: clampedH)
                                                        panOffset = currentPanOffset
                                                    }
                                                }
                                            : nil
                                        )
                                        .onTapGesture(count: 2) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                zoomScale = 1.0
                                                currentZoomScale = 1.0
                                                panOffset = .zero
                                                currentPanOffset = .zero
                                            }
                                        }
                                        .onTapGesture(count: 1) {
                                            if zoomScale == 1.0 {
                                                withAnimation(.spring()) {
                                                    selectedFullScreenImage = nil
                                                }
                                            }
                                        }
                                } placeholder: {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.neonPink))
                                }
                                .tag(img as GalleryImage?)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .scaleEffect(max(0.8, 1.0 - (dragOffset.height / 1000.0)))
                    .offset(y: dragOffset.height)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                // Determine direction on first movement
                                if dragDirection == .none {
                                    if abs(value.translation.height) > abs(value.translation.width) * 1.5 {
                                        if zoomScale <= 1.0 {
                                            dragDirection = .vertical
                                        } else {
                                            dragDirection = .horizontal
                                        }
                                    } else if abs(value.translation.width) > abs(value.translation.height) * 1.5 {
                                        dragDirection = .horizontal
                                    }
                                }
                                
                                // Only track downward drag if locked to vertical
                                if dragDirection == .vertical && value.translation.height > 0 {
                                    dragOffset = value.translation
                                }
                            }
                            .onEnded { value in
                                if dragDirection == .vertical && value.translation.height > 100 {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        selectedFullScreenImage = nil
                                    }
                                }
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    dragOffset = .zero
                                    dragDirection = .none
                                }
                            }
                    )
                    .onChange(of: selectedFullScreenImage) { _ in
                        zoomScale = 1.0
                        currentZoomScale = 1.0
                        panOffset = .zero
                        currentPanOffset = .zero
                    }
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring()) {
                                    selectedFullScreenImage = nil
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white.opacity(0.8))
                                    .neonGlow(color: .black, radius: 4)
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                    .opacity(dragOffset.height > 20 ? 0 : 1)
                    .animation(.easeInOut, value: dragOffset.height)
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .onAppear(perform: loadMachineDetails)
        .navigationBarTitle("CABINET DETAILS", displayMode: .inline)
        .navigationBarHidden(selectedFullScreenImage != nil)
        .navigationBarBackButtonHidden(selectedFullScreenImage != nil)
        .sheet(isPresented: $isShowingLogScore) {
            LogScoreSheetView(machineKey: currentMachineId ?? machineId) {
                highScores = DatabaseManager.shared.fetchHighScores(machineKey: currentMachineId ?? machineId)
            }
        }
        .sheet(item: $selectedScoreToEdit) { score in
            LogScoreSheetView(machineKey: currentMachineId ?? machineId, scoreToEdit: score) {
                highScores = DatabaseManager.shared.fetchHighScores(machineKey: currentMachineId ?? machineId)
            }
        }
    }
    
    private func loadMachineDetails() {
        let key = currentMachineId ?? machineId
        if let fetched = DatabaseManager.shared.getMachine(byKey: key) {
            machine = fetched
            highScores = DatabaseManager.shared.fetchHighScores(machineKey: key)
            
            if let slug = fetched.slugName, !slug.isEmpty {
                loadGallery(slug: slug)
            }
        }
    }
    
    private func loadGallery(slug: String) {
        isGalleryLoading = true
        Task {
            guard let url = URL(string: "https://pinside.com/pinball/machine/\(slug)/gallery") else {
                DispatchQueue.main.async { self.isGalleryLoading = false }
                return
            }
            
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:151.0) Gecko/20100101 Firefox/151.0", forHTTPHeaderField: "User-Agent")
            
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                if let html = String(data: data, encoding: .utf8) {
                    let pattern = "href=\"(https://imgproxy\\.pinside\\.com/[^\"]+rs:fit:(?:1024|2048)[^\"]+)\"[^>]*>\\s*<img[^>]+src=\"(https://imgproxy\\.pinside\\.com/[^\"]+rs:fit:460:460[^\"]+)\""
                    let regex = try NSRegularExpression(pattern: pattern, options: [])
                    let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
                    
                    var images: [GalleryImage] = []
                    for match in matches {
                        if match.numberOfRanges >= 3 {
                            if let highRange = Range(match.range(at: 1), in: html),
                               let thumbRange = Range(match.range(at: 2), in: html) {
                                let highUrl = String(html[highRange])
                                let thumbUrl = String(html[thumbRange])
                                
                                if !images.contains(where: { $0.thumbnailURL == thumbUrl }) {
                                    images.append(GalleryImage(thumbnailURL: thumbUrl, highResURL: highUrl))
                                }
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.galleryImages = images
                        self.isGalleryLoading = false
                    }
                }
            } catch {
                print("DB Manager Error: Failed to fetch gallery images: \(error)")
                DispatchQueue.main.async { self.isGalleryLoading = false }
            }
        }
    }
    
    private func toggleOwned() {
        guard var updated = machine else { return }
        updated.isOwned.toggle()
        DatabaseManager.shared.setOwned(key: updated.machineKey, isOwned: updated.isOwned)
        machine = updated
        showToast(message: updated.isOwned ? "Added to My Collection!" : "Removed from My Collection")
    }
    
    private func toggleFavorite() {
        guard var updated = machine else { return }
        updated.isFavorite.toggle()
        DatabaseManager.shared.setFavorite(key: updated.machineKey, isFavorite: updated.isFavorite)
        machine = updated
        showToast(message: updated.isFavorite ? "Added to Wishlist!" : "Removed from Wishlist")
    }
    
    private func showToast(message: String) {
        toastMessage = message
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
}

// Subview: Grid of mechanical specifications
struct GridView: View {
    let machine: PinballMachine
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                SpecLabel(name: "Manufacturer", value: machine.manufName ?? "Unknown")
                Spacer()
                SpecLabel(name: "Year Released", value: machine.yearString)
            }
            Divider().background(Color.gray.opacity(0.3))
            HStack {
                SpecLabel(name: "Flippers", value: "\(machine.machineFlippers ?? 0)")
                Spacer()
                SpecLabel(name: "Bumpers", value: "\(machine.machineBumpers ?? 0)")
            }
            Divider().background(Color.gray.opacity(0.3))
            HStack {
                SpecLabel(name: "Ramps", value: "\(machine.machineRamps ?? 0)")
                Spacer()
                SpecLabel(name: "Magnets", value: "\(machine.machineMagnets ?? 0)")
            }
            Divider().background(Color.gray.opacity(0.3))
            HStack {
                SpecLabel(name: "Release Type", value: machine.machineReleasetype?.capitalized ?? "Unknown")
                Spacer()
                SpecLabel(name: "Display", value: machine.machineDisplay?.capitalized ?? "Unknown")
            }
            Divider().background(Color.gray.opacity(0.3))
            HStack {
                SpecLabel(name: "Production Run", value: machine.machineRow() != nil ? "\(machine.machineRow()!) units" : "Unknown")
                Spacer()
                SpecLabel(name: "Market Value", value: machine.priceString)
            }
        }
    }
}

extension PinballMachine {
    func machineRow() -> Int? {
        return self.machineProdrun
    }
}

struct SpecLabel: View {
    let name: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name.uppercased())
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .tracking(1)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Subview: Standard detail text container
struct DetailSection: View {
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(color)
                .fontWeight(.black)
            
            Theme.GlassCard {
                Text(content)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }
}
