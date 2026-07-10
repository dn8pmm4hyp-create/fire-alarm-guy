import SwiftUI

/// Create/edit screen for a service visit record, with PDF export via ShareLink.
struct ServiceFormEditor: View {
    @EnvironmentObject private var store: FormsStore
    @Environment(\.dismiss) private var dismiss

    @State var form: ServiceForm
    let isNew: Bool

    @State private var exportedPDF: URL?

    var body: some View {
        Form {
            Section("Site") {
                TextField("Site name", text: $form.siteName)
                TextField("Address", text: $form.siteAddress, axis: .vertical)
                TextField("Client", text: $form.clientName)
            }

            Section("System") {
                TextField("Panel make & model", text: $form.panelMakeModel)
                Picker("Category", selection: $form.category) {
                    ForEach(ServiceForm.SystemCategory.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                Stepper("Zones: \(form.zoneCount)", value: $form.zoneCount, in: 1...99)
            }

            Section("Visit") {
                DatePicker("Date", selection: $form.visitDate, displayedComponents: .date)
                Stepper("Devices tested: \(form.devicesTested)", value: $form.devicesTested, in: 0...999)
                TextField("Work carried out", text: $form.workCarriedOut, axis: .vertical)
                    .lineLimit(3...8)
                Picker("Outcome", selection: $form.outcome) {
                    ForEach(ServiceForm.Outcome.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
            }

            defectsSection

            Section("Sign-off") {
                TextField("Engineer", text: $form.engineerName)
                TextField("Company", text: $form.companyName)
            }

            if !isNew {
                Section {
                    exportButton
                }
            }
        }
        .navigationTitle(isNew ? "New Service Form" : form.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveAndClose() }
            }
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: Defects

    private var defectsSection: some View {
        Section("Defects") {
            ForEach($form.defects) { $defect in
                HStack {
                    Button {
                        defect.isResolved.toggle()
                    } label: {
                        Image(systemName: defect.isResolved ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(defect.isResolved ? Theme.healthy : .secondary)
                    }
                    .buttonStyle(.plain)
                    TextField("Defect description", text: $defect.description, axis: .vertical)
                }
            }
            .onDelete { form.defects.remove(atOffsets: $0) }

            Button {
                form.defects.append(ServiceForm.Defect())
            } label: {
                Label("Add defect", systemImage: "plus.circle")
            }
        }
    }

    // MARK: Export

    @ViewBuilder
    private var exportButton: some View {
        if let exportedPDF {
            ShareLink(item: exportedPDF) {
                Label("Share PDF", systemImage: "square.and.arrow.up")
            }
        } else {
            Button {
                exportedPDF = try? FormPDFExporter.export(form)
            } label: {
                Label("Generate PDF", systemImage: "doc.richtext")
            }
        }
    }

    private func saveAndClose() {
        if isNew {
            store.add(form)
        } else {
            store.update(form)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ServiceFormEditor(form: ServiceForm(), isNew: true)
    }
    .environmentObject(FormsStore())
}
