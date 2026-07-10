import SwiftUI

/// Voltage drop over a two-core cable run at a given load current.
/// Vd = I × (2 × L/1000 × r), where r is core resistance in Ω/km.
struct VoltageDropCalculatorView: View {
    @State private var lengthMetres = 100.0
    @State private var loadCurrent = 0.5
    @State private var supplyVoltage = 24.0
    @State private var csaIndex = 1   // default 1.5 mm²

    private var loopResistance: Double {
        2 * (lengthMetres / 1000) * CableData.resistancePerKm[csaIndex].ohmsPerKm
    }

    private var voltageDrop: Double { loadCurrent * loopResistance }
    private var voltageAtEnd: Double { supplyVoltage - voltageDrop }
    private var dropPercent: Double { supplyVoltage > 0 ? voltageDrop / supplyVoltage * 100 : 0 }

    /// Most devices tolerate down to ~18 V on a nominal 24 V circuit.
    private var isAcceptable: Bool { voltageAtEnd >= supplyVoltage * 0.75 }

    var body: some View {
        Form {
            Section {
                ResultCard(title: "Voltage at end of line",
                           value: voltageAtEnd.formatted(.number.precision(.fractionLength(2))) + " V",
                           detail: String(format: "Drop %.2f V (%.1f%%) over %.0f m loop", voltageDrop, dropPercent, lengthMetres),
                           tint: isAcceptable ? Theme.healthy : Theme.accent)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section("Circuit") {
                NumberField(label: "Cable length (one way)", unit: "m", value: $lengthMetres)
                NumberField(label: "Load current", unit: "A", value: $loadCurrent)
                NumberField(label: "Supply voltage", unit: "V", value: $supplyVoltage)
                Picker("Cable CSA", selection: $csaIndex) {
                    ForEach(CableData.resistancePerKm.indices, id: \.self) { i in
                        Text(CableData.resistancePerKm[i].label).tag(i)
                    }
                }
            }
            Section {
                Text("Uses two-core loop resistance (out and back). Check the minimum operating voltage of end-of-line devices at full alarm load — sounder circuits are the usual worry.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Voltage Drop")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { VoltageDropCalculatorView() }
}
