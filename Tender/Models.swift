import Foundation

enum CurrencyKind: String, Codable, CaseIterable, Identifiable {
    case coin = "Coin"
    case bill = "Bill"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .coin: return "circlebadge.fill"
        case .bill: return "banknote.fill"
        }
    }
}

enum ItemCondition: String, Codable, CaseIterable, Identifiable {
    case mint = "Mint"
    case fine = "Fine"
    case worn = "Worn"
    case damaged = "Damaged"

    var id: String { rawValue }
}

/// Continent classification drives the Pro-only world-coverage bonus feature.
/// Free text country names are matched (case-insensitively, best-effort) to
/// a continent for the coverage map; unmatched countries simply don't count
/// toward any continent's coverage but are still tracked normally.
enum Continent: String, Codable, CaseIterable, Identifiable {
    case africa = "Africa"
    case asia = "Asia"
    case europe = "Europe"
    case northAmerica = "North America"
    case southAmerica = "South America"
    case oceania = "Oceania"
    case antarctica = "Antarctica"

    var id: String { rawValue }
}

struct CurrencyEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var country: String
    var kind: CurrencyKind
    var denomination: String
    var year: String
    var condition: ItemCondition
    var note: String
    /// Optional photo of the physical coin/bill, stored as JPEG Data locally.
    var photoData: Data?
    var faceValueUSD: Double
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        country: String,
        kind: CurrencyKind = .coin,
        denomination: String,
        year: String = "",
        condition: ItemCondition = .fine,
        note: String = "",
        photoData: Data? = nil,
        faceValueUSD: Double = 0,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.country = country
        self.kind = kind
        self.denomination = denomination
        self.year = year
        self.condition = condition
        self.note = note
        self.photoData = photoData
        self.faceValueUSD = faceValueUSD
        self.dateAdded = dateAdded
    }
}

/// Best-effort country -> continent lookup for the coverage bonus feature.
/// Not exhaustive — covers common travel destinations. Unmatched countries
/// are simply excluded from the continent tally, never crash or block use.
enum ContinentLookup {
    private static let table: [String: Continent] = [
        "japan": .asia, "china": .asia, "thailand": .asia, "vietnam": .asia,
        "india": .asia, "south korea": .asia, "korea": .asia, "indonesia": .asia,
        "singapore": .asia, "malaysia": .asia, "philippines": .asia, "cambodia": .asia,
        "israel": .asia, "turkey": .asia, "united arab emirates": .asia, "uae": .asia,
        "nepal": .asia, "sri lanka": .asia, "laos": .asia, "myanmar": .asia,
        "france": .europe, "germany": .europe, "italy": .europe, "spain": .europe,
        "united kingdom": .europe, "uk": .europe, "england": .europe, "greece": .europe,
        "portugal": .europe, "netherlands": .europe, "switzerland": .europe,
        "austria": .europe, "poland": .europe, "czech republic": .europe, "czechia": .europe,
        "hungary": .europe, "sweden": .europe, "norway": .europe, "denmark": .europe,
        "ireland": .europe, "iceland": .europe, "croatia": .europe, "belgium": .europe,
        "egypt": .africa, "morocco": .africa, "south africa": .africa, "kenya": .africa,
        "tanzania": .africa, "tunisia": .africa, "nigeria": .africa, "ghana": .africa,
        "ethiopia": .africa, "namibia": .africa,
        "united states": .northAmerica, "usa": .northAmerica, "canada": .northAmerica,
        "mexico": .northAmerica, "costa rica": .northAmerica, "cuba": .northAmerica,
        "jamaica": .northAmerica, "panama": .northAmerica, "guatemala": .northAmerica,
        "brazil": .southAmerica, "argentina": .southAmerica, "peru": .southAmerica,
        "chile": .southAmerica, "colombia": .southAmerica, "ecuador": .southAmerica,
        "bolivia": .southAmerica, "uruguay": .southAmerica,
        "australia": .oceania, "new zealand": .oceania, "fiji": .oceania,
        "antarctica": .antarctica
    ]

    static func continent(for country: String) -> Continent? {
        table[country.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()]
    }
}
