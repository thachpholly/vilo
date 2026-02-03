import SwiftUI

/// VILO Brand Colors - Vietnamese Flag Theme
extension Color {
    // Primary Colors (Vietnamese Flag)
    static let viloPrimary = Color(hex: "DA251D")      // 🔴 Red - Primary
    static let viloSecondary = Color(hex: "FFCD00")    // 🟡 Yellow - Secondary

    // Background Colors (Dark Theme)
    static let viloBackground = Color(hex: "0D0D0D")   // Pure dark
    static let viloSurface = Color(hex: "1A1A1A")      // Cards, inputs
    static let viloBorder = Color(hex: "2A2A2A")       // Subtle lines

    // Text Colors
    static let viloTextPrimary = Color.white
    static let viloTextSecondary = Color(hex: "888888")

    // Chat Colors
    static let viloSentBubble = Color(hex: "DA251D")   // Red for sent
    static let viloReceivedBubble = Color(hex: "1A1A1A") // Dark for received

    // Status Colors
    static let viloOnline = Color(hex: "FFCD00")       // Yellow online indicator
    static let viloError = Color(hex: "FF4757")        // Error red

    /// Initialize Color from hex string
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
