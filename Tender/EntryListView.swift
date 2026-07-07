import SwiftUI

struct EntryListView: View {
    @EnvironmentObject private var store: TenderStore
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var sheetMode: EntrySheetMode?
    @State private var deletingEntry: CurrencyEntry?
    @State private var showingCoverage = false

    var body: some View {
        NavigationStack {
            ZStack {
                TDTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("Tender")
                                .font(TDTheme.titleFont)
                                .foregroundStyle(TDTheme.ink)
                            Spacer()
                            if purchases.isPro {
                                Button {
                                    showingCoverage = true
                                } label: {
                                    Image(systemName: "globe.americas.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(TDTheme.brass)
                                }
                                .accessibilityIdentifier("coverageButton")
                            }
                            Button {
                                if store.canAddEntry(isPro: purchases.isPro) {
                                    sheetMode = .add
                                } else {
                                    sheetMode = .paywall
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(TDTheme.brass)
                            }
                            .accessibilityIdentifier("addEntryButton")
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                        if !purchases.isPro {
                            Text("Free plan: \(store.entries.count)/\(TenderStore.freeEntryLimit) entries used")
                                .font(.caption)
                                .foregroundStyle(TDTheme.inkFaded)
                                .padding(.horizontal, 18)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "banknote.fill")
                                    .foregroundStyle(TDTheme.brass)
                                Text("Total value: $\(store.totalFaceValueUSD, specifier: "%.2f")")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(TDTheme.ink)
                            }
                            .padding(.horizontal, 18)
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("totalValueLabel")
                        }

                        if store.entries.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 12) {
                                ForEach(store.entries) { entry in
                                    EntryRow(
                                        entry: entry,
                                        duplicateCount: store.duplicateCountryCount(for: entry.country),
                                        isPro: purchases.isPro
                                    ) {
                                        sheetMode = .edit(entry)
                                    } onDelete: {
                                        Haptics.warning()
                                        deletingEntry = entry
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.entries)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
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
            .sheet(isPresented: $showingCoverage) {
                WorldCoverageView().environmentObject(store)
            }
            .confirmationDialog(
                "Remove \(deletingEntry?.country ?? "Entry")?",
                isPresented: Binding(
                    get: { deletingEntry != nil },
                    set: { if !$0 { deletingEntry = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let deletingEntry {
                        store.deleteEntry(deletingEntry.id)
                    }
                    deletingEntry = nil
                }
                Button("Cancel", role: .cancel) { deletingEntry = nil }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "banknote")
                .font(.system(size: 34))
                .foregroundStyle(TDTheme.inkFaded)
            Text("No souvenirs logged yet. Tap + to add your first coin or bill.")
                .font(.subheadline)
                .foregroundStyle(TDTheme.inkFaded)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

private struct EntryRow: View {
    let entry: CurrencyEntry
    let duplicateCount: Int
    let isPro: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(TDTheme.surfaceRaised)
                Image(systemName: entry.kind.symbolName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(TDTheme.brass)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if let uiImage = entry.photoData.flatMap({ UIImage(data: $0) }) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 18, height: 18)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Text(entry.country)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TDTheme.ink)
                    if isPro && duplicateCount > 1 {
                        Text("x\(duplicateCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(TDTheme.backdrop)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(TDTheme.stampRed))
                            .accessibilityIdentifier("dupBadge_\(entry.country)")
                    }
                }
                HStack(spacing: 6) {
                    Text(entry.denomination)
                        .font(.caption)
                        .foregroundStyle(TDTheme.inkFaded)
                    if !entry.year.isEmpty {
                        Text("· \(entry.year)")
                            .font(.caption)
                            .foregroundStyle(TDTheme.inkFaded)
                    }
                    Text("· \(entry.condition.rawValue)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(TDTheme.brass)
                }
            }

            Spacer()

            Menu {
                Button(action: onEdit) {
                    Label("Edit Entry", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Remove Entry", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(TDTheme.inkFaded)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("entryMenu_\(entry.country)_\(entry.denomination)")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(TDTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(TDTheme.rule, lineWidth: 1.5)
        )
    }
}

#Preview {
    EntryListView()
        .environmentObject(TenderStore())
        .environmentObject(PurchaseManager())
}
