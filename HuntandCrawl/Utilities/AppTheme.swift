import SwiftUI

// MARK: - App Colors
struct AppColors {
    static let primary = Color("PrimaryColor", bundle: nil) // A vibrant blue
    static let secondary = Color("SecondaryColor", bundle: nil) // A purple shade
    static let accent = Color("AccentColor", bundle: nil) // An orange accent
    
    // Default colors if custom colors aren't defined in the asset catalog
    static let defaultPrimary = Color.blue
    static let defaultSecondary = Color.purple
    static let defaultAccent = Color(hex: "#FF9900")
    
    // Text and background colors
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let text = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    
    // Card colors
    static let cardBackground = Color(.systemBackground)
    static let cardShadow = Color.black.opacity(0.1)
    
    // Type-specific colors
    static let huntColor = Color.blue.opacity(0.8)
    static let barCrawlColor = Color.purple.opacity(0.8)
    
    // Status colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let inactive = Color.gray
}

// MARK: - Text Styles
struct AppTextStyles {
    // Titles
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.bold)
    static let title2 = Font.title2.weight(.bold)
    static let title3 = Font.title3.weight(.semibold)
    
    // Body text
    static let headline = Font.headline
    static let body = Font.body
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote.weight(.regular)
    static let caption = Font.caption
    static let caption2 = Font.caption2
}

// MARK: - Card Styles
struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16
    var shadowRadius: CGFloat = 4
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: AppColors.cardShadow, radius: shadowRadius, x: 0, y: 2)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(AppColors.defaultPrimary)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(AppColors.defaultSecondary)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

// MARK: - Extensions
extension View {
    func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 4) -> some View {
        self.modifier(CardStyle(padding: padding, cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}

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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 