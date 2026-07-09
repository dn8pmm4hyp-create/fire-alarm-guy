import SwiftUI

/// Hub listing the eight engineering calculators.
struct ToolsView: View {
    private struct Tool: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let destination: AnyView
    }

    private var tools: [Tool] {
        [
            Tool(title: "Standby Battery",
                 subtitle: "BS 5839-1 battery capacity",
                 icon: "battery.100",
                 destination: AnyView(BatteryCalculatorView())),
            Tool(title: "Voltage Drop",
                 subtitle: "Volt drop over cable runs",
                 icon: "bolt.fill",
                 destination: AnyView(VoltageDropCalculatorView())),
            Tool(title: "Ohm's Law",
                 subtitle: "V, I, R and power",
                 icon: "waveform.path",
                 destination: AnyView(OhmsLawCalculatorView())),
            Tool(title: "Cable Resistance",
                 subtitle: "Loop resistance by CSA & length",
                 icon: "cable.connector",
                 destination: AnyView(CableResistanceCalculatorView())),
            Tool(title: "PSU Loading",
                 subtitle: "Power supply headroom check",
                 icon: "powerplug.fill",
                 destination: AnyView(PSULoadingCalculatorView())),
            Tool(title: "Loop Loading",
                 subtitle: "Addressable loop current & devices",
                 icon: "point.3.connected.trianglepath.dotted",
                 destination: AnyView(LoopLoadingCalculatorView())),
            Tool(title: "Sound Level",
                 subtitle: "dB(A) at distance from sounder",
                 icon: "speaker.wave.3.fill",
                 destination: AnyView(SoundLevelCalculatorView())),
            Tool(title: "Detector Spacing",
                 subtitle: "Detectors needed for a room",
                 icon: "sensor.fill",
                 destination: AnyView(DetectorSpacingCalculatorView())),
        ]
    }

    var body: some View {
        NavigationStack {
            List(tools) { tool in
                NavigationLink {
                    tool.destination
                } label: {
                    HStack(spacing: Theme.spacing) {
                        Image(systemName: tool.icon)
                            .font(.title3)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tool.title).font(.headline)
                            Text(tool.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Tools")
        }
    }
}

// MARK: - Shared calculator data

/// Conductor resistance for common fire cable CSAs, ohms per km per core at 20 °C.
enum CableData {
    static let resistancePerKm: [(label: String, csa: Double, ohmsPerKm: Double)] = [
        ("1.0 mm²", 1.0, 18.1),
        ("1.5 mm²", 1.5, 12.1),
        ("2.5 mm²", 2.5, 7.41),
        ("4.0 mm²", 4.0, 4.61),
    ]
}

#Preview {
    ToolsView()
}
