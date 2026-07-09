import SwiftUI

/// Checks a power supply against its connected load, keeping 20% headroom
/// and confirming the battery charger can support the standby load.
struct PSULoadingCalculatorView: View {
    @State private var psuRating = 3.0        // amps
    @State private var panelLoad = 0.25
    @State private var detectorLoad = 0.15
    @State private var sounderLoad = 1.1
    @State private var ancillaryLoad = 0.2

    private var totalLoad: Double { panelLoad + detectorLoad + sounderLoad + ancillaryLoad }
    private var usableRating: Double { psuRating * 0.8 }
    private var headroom: Double { usableRating - totalLoad }
    private var loadPercent: Double { psuRating > 0 ? totalLoad / psuRating * 100 : 0 }

    var body: some View {
        Form {
            Section {
                ResultCard(title: "Total alarm load",
                           value: totalLoad.formatted(.number.precision(.fractionLength(2))) + " A",
                           detail: String(format: "%.0f%% of PSU rating — %@", loadPercent,
                                          headroom >= 0 ? "OK with 20% margin" : "OVERLOADED"),
                           tint: headroom >= 0 ? Theme.healthy : Theme.accent)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section("Power supply") {
                NumberField(label: "PSU rating", unit: "A", value: $psuRating)
            }
            Section("Connected loads (full alarm)") {
                NumberField(label: "Panel electronics", unit: "A", value: $panelLoad)
                NumberField(label: "Detection devices", unit: "A", value: $detectorLoad)
                NumberField(label: "Sounders / VADs", unit: "A", value: $sounderLoad)
                NumberField(label: "Ancillaries (relays, door holders…)", unit: "A", value: $ancillaryLoad)
            }
            Section {
                Text("Keep the full-alarm load at or below 80% of the PSU rating so capacity remains for battery charging and tolerance. Size the standby battery separately with the Battery calculator.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("PSU Loading")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { PSULoadingCalculatorView() }
}
