import Foundation

@MainActor
final class TenderStore: ObservableObject {
    @Published private(set) var entries: [CurrencyEntry] = []

    static let freeEntryLimit = 15

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("tender_entries.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if entries.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        entries = [
            CurrencyEntry(country: "Japan", kind: .coin, denomination: "100 Yen", year: "2019",
                          condition: .fine, note: "Found in change from a Kyoto vending machine.",
                          faceValueUSD: 0.68),
            CurrencyEntry(country: "France", kind: .bill, denomination: "10 Euro", year: "2017",
                          condition: .mint, note: "Souvenir from a Paris cafe, kept as a keepsake.",
                          faceValueUSD: 10.80)
        ]
        save()
    }

    func canAddEntry(isPro: Bool) -> Bool {
        isPro || entries.count < Self.freeEntryLimit
    }

    @discardableResult
    func addEntry(
        country: String, kind: CurrencyKind, denomination: String, year: String,
        condition: ItemCondition, note: String, photoData: Data?, faceValueUSD: Double, isPro: Bool
    ) -> Bool {
        let trimmedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDenom = denomination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCountry.isEmpty, !trimmedDenom.isEmpty, canAddEntry(isPro: isPro) else { return false }
        let entry = CurrencyEntry(
            country: trimmedCountry, kind: kind, denomination: trimmedDenom, year: year,
            condition: condition, note: note, photoData: photoData, faceValueUSD: max(0, faceValueUSD)
        )
        entries.append(entry)
        save()
        return true
    }

    func updateEntry(
        _ id: UUID, country: String, kind: CurrencyKind, denomination: String, year: String,
        condition: ItemCondition, note: String, photoData: Data?, faceValueUSD: Double
    ) {
        let trimmedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDenom = denomination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCountry.isEmpty, !trimmedDenom.isEmpty, let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].country = trimmedCountry
        entries[idx].kind = kind
        entries[idx].denomination = trimmedDenom
        entries[idx].year = year
        entries[idx].condition = condition
        entries[idx].note = note
        entries[idx].photoData = photoData
        entries[idx].faceValueUSD = max(0, faceValueUSD)
        save()
    }

    func deleteEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func moveEntries(from source: IndexSet, to destination: Int) {
        entries.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func deleteAllData() {
        entries = []
        seedDefaults()
    }

    // MARK: - Bonus feature: world coverage + total face value (Pro)

    var totalFaceValueUSD: Double {
        entries.reduce(0) { $0 + $1.faceValueUSD }
    }

    var uniqueCountries: [String] {
        Array(Set(entries.map { $0.country.trimmingCharacters(in: .whitespacesAndNewlines) }))
            .filter { !$0.isEmpty }
            .sorted()
    }

    /// Continents with at least one logged country, driving the Pro world-map visual.
    var coveredContinents: Set<Continent> {
        Set(uniqueCountries.compactMap { ContinentLookup.continent(for: $0) })
    }

    /// Countries with more than one entry — the "duplicate country" rarity badge.
    func duplicateCountryCount(for country: String) -> Int {
        entries.filter { $0.country.caseInsensitiveCompare(country) == .orderedSame }.count
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var entries: [CurrencyEntry]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            entries = decoded.entries
        }
    }

    private func save() {
        let snapshot = Snapshot(entries: entries)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
