import SwiftUI

/// Classic V / I / R solver — enter any two, the third and power are calculated.
struct OhmsLawCalculatorView: View {
    enum Solving: String, CaseIterable, Identifiable {
        case voltage = "Voltage"
        case current = "Current"
        case resistance = "Resistance"
        var id: String { rawValue }
    }

    @State private var solving: Solving = .resistance
    @State private var voltage = 24.0
    @State private var current = 0.02
    @State private var resistance = 4700.0

    private var result: (value: Double, unit: String) {
        switch solving {
        case .voltage: return (current * resistance, "V")
        case .current: return (resistance == 0 ? 0 : voltage / resistance, "A")
        case .resistance: return (current == 0 ? 0 : voltage / current, "Ω")
        }
    }

    private var power: Double {
        switch solving {
        case .voltage: return current * current * resistance
        case .current: return resistance == 0 ? 0 : voltage * voltage / resistance
        case .resistance: return voltage * current
        }
    }

    var body: some View {
        Form {
            Section {
                ResultCard(title: "\(solving.rawValue) =",
                           value: formatted(result.value) + " " + result.unit,
                           detail: "Power: " + formatted(power) + " W")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section("Solve for") {
                Picker("Solve for", selection: $solving) {
                    ForEach(Solving.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Section("Known values") {
                if solving != .voltage {
                    NumberField(label: "Voltage", unit: "V", value: $voltage)
                }
                if solving != .current {
                    NumberField(label: "Current", unit: "A", value: $current)
                }
                if solving != .resistance {
                    NumberField(label: "Resistance", unit: "Ω", value: $resistance)
                }
            }
        }
        .navigationTitle("Ohm's Law")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.significantDigits(1...4)))
    }
}

#Preview {
    NavigationStack { OhmsLawCalculatorView() }
}
