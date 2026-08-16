import SwiftUI

struct Theme {
    // Colors
    static let arcadeBlack = Color(hex: "0A0A0E")
    static let darkGray = Color(hex: "14141E")
    static let cardBg = Color(hex: "1A1A26")
    
    static let neonPink = Color(hex: "FF007F")
    static let neonCyan = Color(hex: "00F0FF")
    static let neonPurple = Color(hex: "9D00FF")
    static let neonGold = Color(hex: "FFC700")
    static let neonGreen = Color(hex: "39FF14")
    
    // Glassmorphism card helper
    struct GlassCard<Content: View>: View {
        var content: Content
        
        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        var body: some View {
            content
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.03))
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.cardBg.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.neonPink.opacity(0.4), Theme.neonCyan.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Theme.neonPink.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

// Extends Color to support Hex initializers
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Neon Glow modifier
struct NeonGlow: ViewModifier {
    var color: Color
    var radius: CGFloat = 8
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius)
            .shadow(color: color.opacity(0.5), radius: radius * 1.5)
    }
}

extension View {
    func neonGlow(color: Color, radius: CGFloat = 8) -> some View {
        self.modifier(NeonGlow(color: color, radius: radius))
    }
}

// Cyberpunk grid backdrop
struct CyberGrid: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let step: CGFloat = 40
                // Vertical lines
                var x: CGFloat = 0
                while x < geo.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    x += step
                }
                // Horizontal lines
                var y: CGFloat = 0
                while y < geo.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    y += step
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Theme.neonPurple.opacity(0.12), Theme.neonCyan.opacity(0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
        }
        .background(Theme.arcadeBlack)
        .ignoresSafeArea()
    }
}
