import SwiftUI

/// Expected loop resistance for a cable run — handy for comparing against a
/// measured end-of-line reading to spot bad joints or wrong terminations.
struct CableResistanceCalculatorView: View {
    @State private var lengthMetres = 150.0
    @State private var csaIndex = 1   // default 1.5 mm²
    @State private var measuredOhms = 0.0

    private var expectedLoop: Double {
        2 * (lengthMetres / 1000) * CableData.resistancePerKm[csaIndex].ohmsPerKm
    }

    private var comparison: String? {
        guard measuredOhms > 0 else { return nil }
        let delta = measuredOhms - expectedLoop
        if abs(delta) < max(0.5, expectedLoop * 0.15) {
            return "Measured value is within the expected range."
        }
        return delta > 0
            ? "Measured is high — check for loose terminations or a poor joint."
            : "Measured is low — check the cable route/length assumption."
    }

    var body: some View {
        Form {
            Section {
                ResultCard(title: "Expected loop resistance",
                           value: expectedLoop.formatted(.number.precision(.fractionLength(2))) + " Ω",
                           detail: "\(CableData.resistancePerKm[csaIndex].label) two-core, out and back")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section("Cable run") {
                NumberField(label: "Length (one way)", unit: "m", value: $lengthMetres)
                Picker("Cable CSA", selection: $csaIndex) {
                    ForEach(CableData.resistancePerKm.indices, id: \.self) { i in
                        Text(CableData.resistancePerKm[i].label).tag(i)
                    }
                }
            }
            Section("Compare a meter reading (optional)") {
                NumberField(label: "Measured loop resistance", unit: "Ω", value: $measuredOhms)
                if let comparison {
                    Text(comparison)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Cable Resistance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { CableResistanceCalculatorView() }
}
