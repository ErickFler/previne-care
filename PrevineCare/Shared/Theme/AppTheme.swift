import SwiftUI

enum AppTheme {
    static let primary = Color(red: 0.09, green: 0.42, blue: 0.55)
    static let support = Color(red: 0.15, green: 0.51, blue: 0.36)
    static let warning = Color(red: 0.76, green: 0.34, blue: 0.18)
    static let surface = Color(.secondarySystemBackground)
    static let background = Color(.systemBackground)
    static let destructive = Color.red

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 8
        static let control: CGFloat = 8
    }

    enum Typography {
        static let title = Font.title2.bold()
        static let cardTitle = Font.headline
        static let body = Font.body
        static let caption = Font.caption
    }

    static func statusColor(for level: RiskLevel) -> Color {
        switch level {
        case .low: support
        case .medium: warning
        case .high: .red
        }
    }
}

struct CareCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            content
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    var color: Color = AppTheme.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(.white)
            .background(color.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control))
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    var color: Color = AppTheme.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(color)
            .background(color.opacity(configuration.isPressed ? 0.16 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control))
    }
}
