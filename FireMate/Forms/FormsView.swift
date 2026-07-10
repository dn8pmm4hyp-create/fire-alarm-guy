import SwiftUI

/// List of saved service visit records, with add/delete and PDF export.
struct FormsView: View {
    @EnvironmentObject private var store: FormsStore
    @EnvironmentObject private var settings: SettingsStore
    @State private var newForm: ServiceForm?

    var body: some View {
        NavigationStack {
            Group {
                if store.forms.isEmpty {
                    emptyState
                } else {
                    formList
                }
            }
            .navigationTitle("Service Forms")
            .toolbar {
                Button {
                    var form = ServiceForm()
                    form.engineerName = settings.engineerName
                    form.companyName = settings.companyName
                    newForm = form
                } label: {
                    Label("New form", systemImage: "plus")
                }
            }
            .sheet(item: $newForm) { form in
                NavigationStack {
                    ServiceFormEditor(form: form, isNew: true)
                }
            }
        }
    }

    private var formList: some View {
        List {
            ForEach(store.forms) { form in
                NavigationLink {
                    ServiceFormEditor(form: form, isNew: false)
                } label: {
                    FormRow(form: form)
                }
            }
            .onDelete { store.delete(at: $0) }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No service forms yet",
            systemImage: "doc.text",
            description: Text("Tap + to record an inspection or service visit, then export it as a PDF for the client.")
        )
    }
}

private struct FormRow: View {
    let form: ServiceForm

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(form.displayTitle).font(.headline)
                Spacer()
                if form.hasOpenDefects {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.amber)
                }
            }
            HStack {
                Text(form.visitDate, style: .date)
                Text("·")
                Text(form.outcome.rawValue)
                    .foregroundStyle(form.outcome == .satisfactory ? Theme.healthy : Theme.amber)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    FormsView()
        .environmentObject(FormsStore())
        .environmentObject(SettingsStore())
}
