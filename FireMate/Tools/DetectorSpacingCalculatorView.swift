import SwiftUI

/// Estimates how many point detectors a rectangular room needs from the
/// BS 5839-1 coverage radii (smoke 7.5 m, heat 5.3 m).
struct DetectorSpacingCalculatorView: View {
    enum DetectorType: String, CaseIterable, Identifiable {
        case smoke = "Smoke"
        case heat = "Heat"
        var id: String { rawValue }

        /// Individual coverage radius in metres per BS 5839-1.
        var radius: Double { self == .smoke ? 7.5 : 5.3 }
        /// Maximum grid spacing between detectors (radius × √2).
        var gridSpacing: Double { radius * 2.0.squareRoot() }
    }

    @State private var detectorType: DetectorType = .smoke
    @State private var roomLength = 20.0
    @State private var roomWidth = 12.0

    private var countAlongLength: Int {
        max(1, Int((roomLength / detectorType.gridSpacing).rounded(.up)))
    }
    private var countAlongWidth: Int {
        max(1, Int((roomWidth / detectorType.gridSpacing).rounded(.up)))
    }
    private var totalDetectors: Int { countAlongLength * countAlongWidth }

    var body: some View {
        Form {
            Section {
                ResultCard(title: "Detectors required",
                           value: "\(totalDetectors)",
                           detail: "\(countAlongLength) × \(countAlongWidth) grid, max spacing "
                               + detectorType.gridSpacing.formatted(.number.precision(.fractionLength(1))) + " m")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section("Detector") {
                Picker("Type", selection: $detectorType) {
                    ForEach(DetectorType.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                LabeledContent("Coverage radius",
                               value: detectorType.radius.formatted() + " m")
            }
            Section("Room") {
                NumberField(label: "Length", unit: "m", value: $roomLength)
                NumberField(label: "Width", unit: "m", value: $roomWidth)
            }
            Section {
                Text("Flat-ceiling estimate for rectangular rooms. Pitched ceilings, beams over 10% of ceiling height, voids and obstructions all change the layout — check BS 5839-1 clause 22 for the detail.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Detector Spacing")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { DetectorSpacingCalculatorView() }
}
