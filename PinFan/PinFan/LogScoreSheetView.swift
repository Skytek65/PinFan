import SwiftUI

struct LogScoreSheetView: View {
    let machineKey: Int
    var scoreToEdit: HighScore? = nil
    
    @Environment(\.dismiss) var dismiss
    
    @State private var scoreString = ""
    @State private var initials = ""
    @State private var scoreDate = Date()
    @State private var notes = ""
    @State private var errorMessage = ""
    
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.arcadeBlack.ignoresSafeArea()
                CyberGrid()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(Theme.neonPink)
                                .fontWeight(.bold)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.neonPink.opacity(0.1)))
                                .padding(.horizontal)
                        }
                        
                        // Form Card
                        Theme.GlassCard {
                            VStack(alignment: .leading, spacing: 20) {
                                // Score Input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("SCORE")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(Theme.neonCyan)
                                        .fontWeight(.black)
                                    
                                    HStack {
                                        Image(systemName: "trophy.fill")
                                            .foregroundColor(Theme.neonGold)
                                        TextField("0", text: $scoreString)
                                            .keyboardType(.numberPad)
                                            .foregroundColor(.white)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .onChange(of: scoreString) { newValue in
                                                // Only allow numbers
                                                let filtered = newValue.filter { "0123456789".contains($0) }
                                                if filtered != newValue {
                                                    self.scoreString = filtered
                                                }
                                            }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.neonCyan.opacity(0.3), lineWidth: 1))
                                }
                                
                                // Initials Input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("PLAYER INITIALS")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(Theme.neonCyan)
                                        .fontWeight(.black)
                                    
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(Theme.neonPink)
                                        TextField("AAA", text: $initials)
                                            .textInputAutocapitalization(.characters)
                                            .foregroundColor(.white)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .onChange(of: initials) { newValue in
                                                // Enforce 3 chars maximum, uppercase, letters only
                                                let filtered = newValue.uppercased().filter { "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains($0) }
                                                if filtered.count > 3 {
                                                    self.initials = String(filtered.prefix(3))
                                                } else {
                                                    self.initials = filtered
                                                }
                                            }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.neonPink.opacity(0.3), lineWidth: 1))
                                }
                                
                                // Date Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("DATE RECORDED")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(Theme.neonCyan)
                                        .fontWeight(.black)
                                    
                                    DatePicker(
                                        "Select Date",
                                        selection: $scoreDate,
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.compact)
                                    .colorScheme(.dark)
                                }
                                
                                // Notes TextField
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("REMARKS")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(Theme.neonCyan)
                                        .fontWeight(.black)
                                    
                                    TextField("Got wizard mode, extra ball, etc.", text: $notes)
                                        .foregroundColor(.white)
                                        .font(.body)
                                    
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.neonPurple.opacity(0.3), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Delete Button (if editing)
                        if let score = scoreToEdit {
                            Button(action: { deleteScore(id: score.scoreId) }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("DELETE SCORE")
                                        .fontWeight(.black)
                                        .tracking(1)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.neonPink))
                                .neonGlow(color: Theme.neonPink, radius: 4)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(scoreToEdit == nil ? "LOG HIGH SCORE" : "EDIT SCORE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveScore()
                    }
                    .foregroundColor(Theme.neonPink)
                    .fontWeight(.bold)
                }
            }
            .onAppear(perform: loadExistingDetails)
        }
        .accentColor(Theme.neonPink)
    }
    
    private func loadExistingDetails() {
        if let score = scoreToEdit {
            scoreString = "\(score.scoreValue)"
            initials = score.playerInitials
            notes = score.notes
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: score.scoreDate) {
                scoreDate = date
            }
        }
    }
    
    private func saveScore() {
        guard let value = Int(scoreString), value > 0 else {
            errorMessage = "Please enter a valid positive score."
            return
        }
        
        guard initials.count == 3 else {
            errorMessage = "Player initials must be exactly 3 characters."
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: scoreDate)
        
        let success: Bool
        if let score = scoreToEdit {
            success = DatabaseManager.shared.updateHighScore(
                scoreId: score.scoreId,
                scoreValue: value,
                playerInitials: initials,
                scoreDate: dateStr,
                notes: notes
            )
        } else {
            success = DatabaseManager.shared.addHighScore(
                machineKey: machineKey,
                scoreValue: value,
                playerInitials: initials,
                scoreDate: dateStr,
                notes: notes
            )
        }
        
        if success {
            onSave()
            dismiss()
        } else {
            errorMessage = "Failed to write high score to SQLite database."
        }
    }
    
    private func deleteScore(id: Int) {
        if DatabaseManager.shared.deleteHighScore(scoreId: id) {
            onSave()
            dismiss()
        } else {
            errorMessage = "Failed to delete score from SQLite database."
        }
    }
}
