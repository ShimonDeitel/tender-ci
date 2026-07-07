import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: TenderStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("tender_haptics_enabled") private var hapticsEnabled: Bool = true
    /// Category-specific preference: default currency unit shown alongside
    /// USD value estimates when adding a new entry.
    @AppStorage("tender_default_currency_hint") private var defaultCurrencyHint: String = "USD"

    @State private var showingDeleteConfirm = false
    @State private var sheetMode: EntrySheetMode?

    var body: some View {
        NavigationStack {
            ZStack {
                TDTheme.backdrop.ignoresSafeArea()

                Form {
                    Section {
                        if purchases.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(TDTheme.brass)
                                Text("Tender Pro unlocked")
                                    .foregroundStyle(TDTheme.ink)
                            }
                        } else {
                            Button {
                                sheetMode = .paywall
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill").foregroundStyle(TDTheme.brass)
                                    Text("Unlock Tender Pro")
                                        .foregroundStyle(TDTheme.ink)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(TDTheme.inkFaded)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(TDTheme.surface)

                    Section("Entries") {
                        ForEach(store.entries) { entry in
                            HStack {
                                Text(entry.country).foregroundStyle(TDTheme.ink)
                                Spacer()
                                Text(entry.denomination)
                                    .font(.caption)
                                    .foregroundStyle(TDTheme.inkFaded)
                                Button {
                                    sheetMode = .edit(entry)
                                } label: {
                                    Image(systemName: "pencil.circle").foregroundStyle(TDTheme.inkFaded)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("editEntry_\(entry.country)_\(entry.denomination)")
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteEntry(entry.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .accessibilityIdentifier("deleteEntrySwipe_\(entry.country)_\(entry.denomination)")
                            }
                        }
                        .onMove { source, destination in
                            store.moveEntries(from: source, to: destination)
                        }

                        Button {
                            if store.canAddEntry(isPro: purchases.isPro) {
                                sheetMode = .add
                            } else {
                                sheetMode = .paywall
                            }
                        } label: {
                            Label("Add Entry", systemImage: "plus.circle")
                                .foregroundStyle(TDTheme.brass)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settingsAddEntryButton")

                        if !purchases.isPro {
                            Text("\(store.entries.count)/\(TenderStore.freeEntryLimit) free entries used")
                                .font(.caption)
                                .foregroundStyle(TDTheme.inkFaded)
                        }
                    }
                    .listRowBackground(TDTheme.surface)

                    Section("Preferences") {
                        Picker("Default Value Currency", selection: $defaultCurrencyHint) {
                            Text("USD").tag("USD")
                            Text("EUR").tag("EUR")
                            Text("GBP").tag("GBP")
                        }
                        .tint(TDTheme.brass)
                        .accessibilityIdentifier("currencyHintPicker")
                        .foregroundStyle(TDTheme.ink)

                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptics", systemImage: "hand.tap.fill")
                                .foregroundStyle(TDTheme.ink)
                        }
                        .tint(TDTheme.brass)
                        .accessibilityIdentifier("hapticsToggle")
                        .onChange(of: hapticsEnabled) { _, newValue in
                            Haptics.enabled = newValue
                        }

                        Button {
                            Task { await purchases.restore() }
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                                .foregroundStyle(TDTheme.ink)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("restorePurchasesButton")
                    }
                    .listRowBackground(TDTheme.surface)

                    Section("About") {
                        Link(destination: URL(string: "https://shimondeitel.github.io/tender-site/privacy.html")!) {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .foregroundStyle(TDTheme.ink)
                        }
                        Link(destination: URL(string: "https://shimondeitel.github.io/tender-site/support.html")!) {
                            Label("Support", systemImage: "questionmark.circle")
                                .foregroundStyle(TDTheme.ink)
                        }
                        Link(destination: URL(string: "mailto:s0533495227@gmail.com")!) {
                            Label("Contact Support", systemImage: "envelope.fill")
                                .foregroundStyle(TDTheme.ink)
                        }
                        HStack {
                            Text("Version").foregroundStyle(TDTheme.ink)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(TDTheme.inkFaded)
                        }
                    }
                    .listRowBackground(TDTheme.surface)

                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash.fill")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deleteAllDataButton")
                    }
                    .listRowBackground(TDTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarBackground(TDTheme.backdrop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { EditButton() }
            .sheet(item: $sheetMode) { mode in
                switch mode {
                case .paywall:
                    PaywallView().environmentObject(purchases)
                case .add, .edit:
                    EntryEditSheet(mode: mode) { country, kind, denom, year, condition, note, photo, value in
                        switch mode {
                        case .add:
                            store.addEntry(country: country, kind: kind, denomination: denom, year: year, condition: condition, note: note, photoData: photo, faceValueUSD: value, isPro: purchases.isPro)
                        case .edit(let entry):
                            store.updateEntry(entry.id, country: country, kind: kind, denomination: denom, year: year, condition: condition, note: note, photoData: photo, faceValueUSD: value)
                        case .paywall:
                            break
                        }
                    }
                }
            }
            .alert("Delete All Data?", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    store.deleteAllData()
                }
            } message: {
                Text("This permanently removes every logged coin and bill. This cannot be undone.")
            }
        }
        .dismissKeyboardOnTap()
    }
}

#Preview {
    SettingsView()
        .environmentObject(TenderStore())
        .environmentObject(PurchaseManager())
}
