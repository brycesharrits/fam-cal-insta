import SwiftUI

struct DatesLayerView: View {
    let projectID: String
    let months: [MonthResponse]

    @Environment(ServiceContainer.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = DatesLayerViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Import from device") {
                    Button {
                        Task { await viewModel.importBirthdays(eventKitService: services.eventKitService) }
                    } label: {
                        Label("Import Birthdays from Contacts", systemImage: "person.crop.circle.badge.plus")
                    }

                    Button {
                        viewModel.showCalendarPicker = true
                    } label: {
                        Label("Import from Calendar App", systemImage: "calendar")
                    }
                }

                Section("Add manually") {
                    Button {
                        viewModel.showManualEntry = true
                    } label: {
                        Label("Add a date", systemImage: "plus.circle")
                    }
                }

                if !viewModel.familyDates.isEmpty {
                    Section("Added dates (\(viewModel.familyDates.count))") {
                        ForEach(viewModel.familyDates) { date in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(date.title).font(.body)
                                    if let month = date.date.month, let day = date.date.day {
                                        Text(String(format: "%@ %d", monthName(month), day))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: sourceIcon(date.source))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indices in
                            viewModel.familyDates.remove(atOffsets: indices)
                        }
                    }
                }
            }
            .navigationTitle("Family Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showManualEntry) {
                ManualDateEntryView { newDate in
                    viewModel.familyDates.append(newDate)
                }
            }
        }
    }

    private func monthName(_ month: Int) -> String {
        let names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        return names[safe: month - 1] ?? ""
    }

    private func sourceIcon(_ source: FamilyDateSource) -> String {
        switch source {
        case .contacts: return "person.crop.circle"
        case .calendar: return "calendar"
        case .manual: return "hand.point.up"
        }
    }
}
