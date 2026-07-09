import Foundation

// MARK: - Service form model

/// A periodic inspection & servicing record, loosely following the
/// BS 5839-1 model service certificate.
struct ServiceForm: Identifiable, Codable, Equatable {
    enum SystemCategory: String, Codable, CaseIterable {
        case l1 = "L1", l2 = "L2", l3 = "L3", l4 = "L4", l5 = "L5"
        case p1 = "P1", p2 = "P2"
        case m = "M"
    }

    enum Outcome: String, Codable, CaseIterable {
        case satisfactory = "Satisfactory"
        case defectsRecorded = "Defects recorded"
        case unsatisfactory = "Unsatisfactory"
    }

    struct Defect: Identifiable, Codable, Equatable {
        var id = UUID()
        var description = ""
        var isResolved = false
    }

    var id = UUID()
    var createdAt = Date()

    // Site
    var siteName = ""
    var siteAddress = ""
    var clientName = ""

    // System
    var panelMakeModel = ""
    var category: SystemCategory = .l2
    var zoneCount = 1
    var batteryReplacedDate: Date?

    // Visit
    var visitDate = Date()
    var workCarriedOut = ""
    var devicesTested = 0
    var defects: [Defect] = []
    var outcome: Outcome = .satisfactory

    // Sign-off
    var engineerName = ""
    var companyName = ""

    var displayTitle: String {
        siteName.isEmpty ? "Untitled visit" : siteName
    }

    var hasOpenDefects: Bool {
        defects.contains { !$0.isResolved }
    }
}

// MARK: - Persistence

/// Stores forms as a JSON file in the app's Documents directory.
@MainActor
final class FormsStore: ObservableObject {
    @Published var forms: [ServiceForm] = [] {
        didSet { save() }
    }

    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("service-forms.json")
        load()
    }

    func add(_ form: ServiceForm) {
        forms.insert(form, at: 0)
    }

    func update(_ form: ServiceForm) {
        guard let index = forms.firstIndex(where: { $0.id == form.id }) else { return }
        forms[index] = form
    }

    func delete(at offsets: IndexSet) {
        forms.remove(atOffsets: offsets)
    }

    // MARK: Disk

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ServiceForm].self, from: data) else { return }
        forms = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(forms) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
