import SwiftUI

enum AppTheme {
    static let primary = Color(red: 0.09, green: 0.42, blue: 0.55)
    static let support = Color(red: 0.15, green: 0.51, blue: 0.36)
    static let warning = Color(red: 0.76, green: 0.34, blue: 0.18)
    static let surface = Color(.secondarySystemBackground)
    static let background = Color(.systemBackground)

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
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
