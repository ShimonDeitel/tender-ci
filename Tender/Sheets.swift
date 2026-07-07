import SwiftUI
import PhotosUI

/// One unified sheet enum per screen — stacking multiple `.sheet(item:)` or
/// `.alert(...)` modifiers on the same view is a known SwiftUI bug (only the
/// last-declared one reliably fires). Route every sheet through this enum.
enum EntrySheetMode: Identifiable {
    case add
    case edit(CurrencyEntry)
    case paywall

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let entry): return entry.id.uuidString
        case .paywall: return "paywall"
        }
    }
}

struct EntryEditSheet: View {
    let mode: EntrySheetMode
    let onSave: (String, CurrencyKind, String, String, ItemCondition, String, Data?, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var country: String
    @State private var kind: CurrencyKind
    @State private var denomination: String
    @State private var year: String
    @State private var condition: ItemCondition
    @State private var note: String
    @State private var faceValueText: String
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?

    init(mode: EntrySheetMode, onSave: @escaping (String, CurrencyKind, String, String, ItemCondition, String, Data?, Double) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .edit(let entry):
            _country = State(initialValue: entry.country)
            _kind = State(initialValue: entry.kind)
            _denomination = State(initialValue: entry.denomination)
            _year = State(initialValue: entry.year)
            _condition = State(initialValue: entry.condition)
            _note = State(initialValue: entry.note)
            _faceValueText = State(initialValue: entry.faceValueUSD > 0 ? String(format: "%.2f", entry.faceValueUSD) : "")
            _photoData = State(initialValue: entry.photoData)
        default:
            _country = State(initialValue: "")
            _kind = State(initialValue: .coin)
            _denomination = State(initialValue: "")
            _year = State(initialValue: "")
            _condition = State(initialValue: .fine)
            _note = State(initialValue: "")
            _faceValueText = State(initialValue: "")
            _photoData = State(initialValue: nil)
        }
    }

    private var title: String {
        if case .edit = mode { return "Edit Entry" }
        return "New Entry"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Currency") {
                    TextField("Country (e.g. Japan)", text: $country)
                        .accessibilityIdentifier("countryField")

                    Picker("Type", selection: $kind) {
                        ForEach(CurrencyKind.allCases) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    .accessibilityIdentifier("kindPicker")

                    TextField("Denomination (e.g. 100 Yen)", text: $denomination)
                        .accessibilityIdentifier("denominationField")

                    TextField("Year (optional)", text: $year)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("yearField")
                }
                Section("Details") {
                    Picker("Condition", selection: $condition) {
                        ForEach(ItemCondition.allCases) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .accessibilityIdentifier("conditionPicker")

                    HStack {
                        Text("Approx. USD value")
                        Spacer()
                        TextField("0.00", text: $faceValueText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("faceValueField")
                    }

                    TextField("Note: where or how acquired", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityIdentifier("noteField")
                }
                Section("Photo") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(photoData == nil ? "Add Photo" : "Change Photo", systemImage: "camera.fill")
                            .foregroundStyle(TDTheme.brass)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("photoPickerButton")

                    if let photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let value = Double(faceValueText) ?? 0
                        onSave(country, kind, denomination, year, condition, note, photoData, value)
                        dismiss()
                    }
                    .accessibilityIdentifier("entrySaveButton")
                    .disabled(country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || denomination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}
