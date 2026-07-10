import SwiftUI

/// Searchable library of quick-reference notes drawn from BS 5839-1 and
/// everyday site practice. Content is informative shorthand, not a substitute
/// for the published standard.
struct ReferenceView: View {
    @State private var searchText = ""

    private var filteredTopics: [ReferenceTopic] {
        guard !searchText.isEmpty else { return ReferenceTopic.all }
        return ReferenceTopic.all.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.body.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredTopics) { topic in
                NavigationLink {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.spacing) {
                            Label(topic.title, systemImage: topic.icon)
                                .font(.title3.weight(.semibold))
                            Text(topic.body)
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .navigationTitle(topic.title)
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Label(topic.title, systemImage: topic.icon)
                }
            }
            .searchable(text: $searchText, prompt: "Search standards notes")
            .navigationTitle("Reference")
        }
    }
}

// MARK: - Content

struct ReferenceTopic: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let body: String

    static let all: [ReferenceTopic] = [
        ReferenceTopic(
            title: "System categories (BS 5839-1)",
            icon: "list.bullet.rectangle",
            body: """
            Life protection:
            • L1 — detection throughout the whole building.
            • L2 — escape routes, adjoining rooms, plus defined high-risk rooms.
            • L3 — escape routes and rooms opening onto them.
            • L4 — escape routes (corridors and stairways) only.
            • L5 — engineered category for a specific fire safety objective.

            Property protection:
            • P1 — detection throughout the building.
            • P2 — detection in defined high-risk areas only.

            M — manual system (call points only, no automatic detection).
            """),
        ReferenceTopic(
            title: "Detector selection & coverage",
            icon: "sensor.fill",
            body: """
            Coverage radii for point detectors on flat ceilings:
            • Smoke: 7.5 m radius (≈10.6 m grid spacing).
            • Heat: 5.3 m radius (≈7.5 m grid spacing).

            Placement rules of thumb:
            • Keep at least 500 mm from walls, beams and fittings.
            • Mount so the sensing element is 25–600 mm below ceiling (smoke) / 25–150 mm (heat).
            • Ceiling obstructions deeper than 10% of ceiling height act as walls.
            • Choose heat detectors in kitchens/dusty areas; optical smoke in escape routes; multisensor to cut false alarms.
            """),
        ReferenceTopic(
            title: "Manual call points",
            icon: "hand.raised.fill",
            body: """
            • On escape routes, at storey exits and exits to open air.
            • Nobody should travel more than 45 m to reach one (25 m for high-risk areas or where movement is slow).
            • Mounting height 1.4 m ± 200 mm above floor.
            • Weekly test: operate one call point during working hours, rotating around the site.
            """),
        ReferenceTopic(
            title: "Audibility & alarm devices",
            icon: "speaker.wave.3.fill",
            body: """
            Minimum sound levels:
            • 65 dB(A) generally throughout the premises.
            • 60 dB(A) in stairways, small rooms (<60 m²) and points of limited extent.
            • 75 dB(A) at the bedhead in sleeping accommodation.
            • Level should exceed background noise by at least 5 dB(A).

            Rules of thumb: −6 dB per doubling of distance, −20 dB or more through a closed door. Visual alarm devices (VADs) where occupants may be deaf or hearing-impaired, or in high-noise areas.
            """),
        ReferenceTopic(
            title: "Zones",
            icon: "square.grid.3x3",
            body: """
            • A detection zone should not exceed 2,000 m² floor area.
            • Search distance within a zone: 60 m max for locating a fire.
            • A zone should not cover more than one storey, unless total floor area ≤300 m².
            • Stairwells/shafts may be separate zones.
            • Zone plan should be displayed adjacent to the CIE.
            """),
        ReferenceTopic(
            title: "Cabling",
            icon: "cable.connector",
            body: """
            • Fire-resisting cable required for all critical signal paths and power: standard grade (30 min, e.g. BS 7629-1) for most applications, enhanced grade (120 min, BS 8434-2) for unsprinklered buildings over 30 m, phased evacuation, and similar.
            • Segregate from other services; support with fire-resistant fixings (no plastic-only clips).
            • Check volt drop at full alarm load on long sounder circuits.
            """),
        ReferenceTopic(
            title: "Power supplies & batteries",
            icon: "battery.100",
            body: """
            • Mains supply on a dedicated circuit, isolator labelled "FIRE ALARM: DO NOT SWITCH OFF".
            • Standby battery: normally 24 h standby + 30 min alarm; 72 h where a fault might not be actioned promptly.
            • Capacity: C = 1.25 × (T1·I1 + 1.75·I2·T2).
            • Replace VRLA batteries typically every 4–5 years; record the date on the battery and in the log book.
            """),
        ReferenceTopic(
            title: "Servicing & maintenance",
            icon: "wrench.and.screwdriver.fill",
            body: """
            • Periodic inspection & servicing at intervals not exceeding 6 months.
            • Every device function-tested over each 12-month period.
            • Weekly user test (one call point, rotated) plus monthly standby generator/inverter checks where fitted.
            • Record all work, faults and false alarms in the system log book; issue a servicing certificate on completion.
            """),
        ReferenceTopic(
            title: "False alarm management",
            icon: "bell.slash.fill",
            body: """
            • Investigate every unwanted alarm and record the cause.
            • Common fixes: swap ionisation/optical for multisensor or heat, move detectors away from kitchens, showers and dusty work, fit covers during building work, review cause-and-effect delays.
            • Rate above about 1 false alarm per 20 detectors per year warrants investigation.
            """),
        ReferenceTopic(
            title: "Commissioning checks",
            icon: "checkmark.seal.fill",
            body: """
            • 100% device test — every detector, call point and alarm device.
            • Verify sound levels with a meter; record readings.
            • Confirm cause-and-effect programme against the specification.
            • Check battery calculations, cable insulation resistance, earth continuity.
            • Hand over: as-fitted drawings, zone plan, log book, certificates, user training.
            """),
    ]
}

#Preview {
    ReferenceView()
}
