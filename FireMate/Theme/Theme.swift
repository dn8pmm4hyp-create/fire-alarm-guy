import SwiftUI

/// FireMate design system: colours, spacing, type and reusable view styles.
enum Theme {
    // MARK: Colours

    /// Signal red — primary brand/accent colour.
    static let accent = Color(red: 0.86, green: 0.18, blue: 0.12)
    /// Amber used for warnings and "fault" states.
    static let amber = Color(red: 0.95, green: 0.62, blue: 0.05)
    /// Green used for "healthy"/pass states.
    static let healthy = Color(red: 0.18, green: 0.62, blue: 0.35)

    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let screenBackground = Color(.systemGroupedBackground)

    // MARK: Spacing & metrics

    static let spacing: CGFloat = 12
    static let cardCornerRadius: CGFloat = 14

    // MARK: Typography

    static func title(_ text: String) -> Text {
        Text(text).font(.title2.weight(.bold))
    }

    static func resultFont() -> Font {
        .system(.title, design: .rounded).weight(.semibold)
    }
}

// MARK: - Reusable styles

/// Rounded card container used across calculators, forms and the assistant.
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.spacing)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
}

/// Prominent numeric result shown at the top of each calculator.
struct ResultCard: View {
    let title: String
    let value: String
    var detail: String? = nil
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(Theme.resultFont())
                .foregroundStyle(tint)
                .contentTransition(.numericText())
            if let detail {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

/// Labelled numeric input row used by the calculator screens.
struct NumberField: View {
    let label: String
    let unit: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 110)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(minWidth: 34, alignment: .leading)
        }
    }
}
