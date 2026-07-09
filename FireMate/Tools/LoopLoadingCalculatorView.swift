import SwiftUI

/// Addressable loop check: device count against the protocol address limit and
/// total loop current against the loop driver's rating.
struct LoopLoadingCalculatorView: View {
    @State private var deviceCount = 80.0
    @State private var averageQuiescent = 0.35   // mA per device
    @State private var alarmDeviceCount = 20.0   // devices in alarm (sounders etc.)
    @State private var averageAlarm = 5.0        // mA per alarm device
    @State private var loopCapacity = 500.0      // mA
    @State private var addressLimit = 254.0

    private var quiescentTotal: Double { deviceCount * averageQuiescent }
    private var alarmTotal: Double { quiescentTotal + alarmDeviceCount * averageAlarm }
    private var currentOK: Bool { alarmTotal <= loopCapacity * 0.8 }
    private var addressOK: Bool { deviceCount <= addressLimit }

    var body: some View {
        Form {
            Section {
                ResultCard(title: "Loop current in alarm",
                           value: alarmTotal.formatted(.number.precision(.fractionLength(1))) + " mA",
                           detail: statusLine,
                           tint: currentOK && addressOK ? Theme.healthy : Theme.accent)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section("Devices") {
                NumberField(label: "Devices on loop", unit: "", value: $deviceCount)
                NumberField(label: "Avg quiescent per device", unit: "mA", value: $averageQuiescent)
                NumberField(label: "Devices in alarm", unit: "", value: $alarmDeviceCount)
                NumberField(label: "Avg alarm current each", unit: "mA", value: $averageAlarm)
            }
            Section("Loop limits (from panel datasheet)") {
                NumberField(label: "Loop current capacity", unit: "mA", value: $loopCapacity)
                NumberField(label: "Address limit", unit: "", value: $addressLimit)
            }
            Section {
                Text("Aims for ≤80% of the loop driver rating in full alarm. Real device currents vary by protocol — always confirm against the manufacturer's loop calculator for final design.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Loop Loading")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusLine: String {
        var parts: [String] = []
        parts.append(currentOK
            ? String(format: "Within 80%% of %.0f mA capacity", loopCapacity)
            : "Exceeds 80% of loop capacity")
        parts.append(addressOK
            ? String(format: "%.0f of %.0f addresses used", deviceCount, addressLimit)
            : "Too many devices for address limit")
        return parts.joined(separator: " · ")
    }
}

#Preview {
    NavigationStack { LoopLoadingCalculatorView() }
}
