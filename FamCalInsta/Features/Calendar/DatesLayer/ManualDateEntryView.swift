import SwiftUI

struct ManualDateEntryView: View {
    let onAdd: (FamilyDate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedDate = Date()
    @State private var isAnnual = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Event name (e.g. Mom's Birthday)", text: $title)
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    Toggle("Repeats annually", isOn: $isAnnual)
                }
            }
            .navigationTitle("Add Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let cal = Calendar.current
                        let comps = cal.dateComponents([.month, .day], from: selectedDate)
                        let familyDate = FamilyDate(
                            id: UUID(),
                            title: title,
                            date: comps,
                            isAnnual: isAnnual,
                            source: .manual
                        )
                        onAdd(familyDate)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
