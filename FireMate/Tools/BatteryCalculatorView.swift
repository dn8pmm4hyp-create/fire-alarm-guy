import SwiftUI

/// Standby battery sizing to BS 5839-1:
/// C = 1.25 × (T1 × I1 + D × I2 × T2), D = 1.75.
struct BatteryCalculatorView: View {
    @State private var quiescentCurrent = 0.15   // I1, amps
    @State private var alarmCurrent = 1.2        // I2, amps
    @State private var standbyHours = 24.0       // T1
    @State private var alarmMinutes = 30.0       // T2 (entered in minutes)

    private let deratingFactor = 1.75

    private var capacityAh: Double {
        1.25 * (standbyHours * quiescentCurrent
                + deratingFactor * alarmCurrent * (alarmMinutes / 60))
    }

    /// Next standard battery size up from the calculated capacity.
    private var recommendedBattery: String {
        let standardSizes: [Double] = [2.1, 3.2, 7, 12, 17, 24, 38, 65]
        if let fit = standardSizes.first(where: { $0 >= capacityAh }) {
            return "\(fit.formatted()) Ah"
        }
        return "parallel batteries required"
    }

    var body: some View {
        Form {
            Section {
                ResultCard(title: "Minimum capacity",
                           value: capacityAh.formatted(.number.precision(.fractionLength(1))) + " Ah",
                           detail: "Fit next standard size: \(recommendedBattery)")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section("Loads") {
                NumberField(label: "Quiescent current (I1)", unit: "A", value: $quiescentCurrent)
                NumberField(label: "Alarm current (I2)", unit: "A", value: $alarmCurrent)
            }
            Section("Durations") {
                NumberField(label: "Standby period (T1)", unit: "h", value: $standbyHours)
                NumberField(label: "Alarm period (T2)", unit: "min", value: $alarmMinutes)
            }
            Section {
                Text("C = 1.25 × (T1·I1 + 1.75·I2·T2). BS 5839-1 normally requires 24 h standby plus 30 min alarm; use 72 h where the premises are unoccupied and faults may go unactioned.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Standby Battery")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { BatteryCalculatorView() }
}
