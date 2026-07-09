import SwiftUI

/// Estimates sound pressure level at a distance from a sounder using the
/// inverse square law: SPL(d) = SPL@1m − 20·log10(d).
struct SoundLevelCalculatorView: View {
    @State private var soundOutputAt1m = 100.0   // dB(A) @ 1 m from datasheet
    @State private var distance = 10.0           // metres
    @State private var doorsBetween = 0.0        // each closed door ≈ −20 dB
    @State private var target = 65.0             // required dB(A)

    private var levelAtDistance: Double {
        guard distance > 0 else { return soundOutputAt1m }
        return soundOutputAt1m - 20 * log10(distance) - doorsBetween * 20
    }

    private var meetsTarget: Bool { levelAtDistance >= target }

    var body: some View {
        Form {
            Section {
                ResultCard(title: "Estimated level at listener",
                           value: levelAtDistance.formatted(.number.precision(.fractionLength(1))) + " dB(A)",
                           detail: meetsTarget
                               ? "Meets the \(target.formatted()) dB(A) target"
                               : "Below the \(target.formatted()) dB(A) target — add or move sounders",
                           tint: meetsTarget ? Theme.healthy : Theme.accent)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section("Sounder") {
                NumberField(label: "Output at 1 m (datasheet)", unit: "dB", value: $soundOutputAt1m)
                NumberField(label: "Distance to listener", unit: "m", value: $distance)
                NumberField(label: "Closed doors in path", unit: "", value: $doorsBetween)
            }
            Section("Requirement") {
                Picker("Target level", selection: $target) {
                    Text("65 dB(A) — general").tag(65.0)
                    Text("60 dB(A) — stairs / small rooms").tag(60.0)
                    Text("75 dB(A) — bedhead").tag(75.0)
                }
            }
            Section {
                Text("Free-field estimate: −6 dB per doubling of distance, −20 dB per closed door. Furnishings and geometry matter — always verify with a meter on commissioning.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Sound Level")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { SoundLevelCalculatorView() }
}
