import XCTest
@testable import Tender

@MainActor
final class TenderTests: XCTestCase {

    func testContinentLookupMatchesKnownCountry() {
        XCTAssertEqual(ContinentLookup.continent(for: "Japan"), .asia)
        XCTAssertEqual(ContinentLookup.continent(for: "  france "), .europe)
        XCTAssertEqual(ContinentLookup.continent(for: "Unknownland"), nil)
    }

    func testStoreAddEntryRespectsFreeLimit() {
        let store = TenderStore()
        for entry in store.entries { store.deleteEntry(entry.id) }
        for i in 1...15 {
            XCTAssertTrue(store.addEntry(country: "Country\(i)", kind: .coin, denomination: "1 Unit", year: "2020", condition: .fine, note: "", photoData: nil, faceValueUSD: 1, isPro: false))
        }
        XCTAssertFalse(store.addEntry(country: "Country16", kind: .coin, denomination: "1 Unit", year: "2020", condition: .fine, note: "", photoData: nil, faceValueUSD: 1, isPro: false))
        XCTAssertTrue(store.addEntry(country: "Country16", kind: .coin, denomination: "1 Unit", year: "2020", condition: .fine, note: "", photoData: nil, faceValueUSD: 1, isPro: true))
    }

    func testAddEntryRejectsEmptyCountryOrDenomination() {
        let store = TenderStore()
        for entry in store.entries { store.deleteEntry(entry.id) }
        XCTAssertFalse(store.addEntry(country: "", kind: .coin, denomination: "1 Unit", year: "", condition: .fine, note: "", photoData: nil, faceValueUSD: 0, isPro: false))
        XCTAssertFalse(store.addEntry(country: "Peru", kind: .coin, denomination: "  ", year: "", condition: .fine, note: "", photoData: nil, faceValueUSD: 0, isPro: false))
    }

    func testUpdateEntryChangesFields() {
        let store = TenderStore()
        for entry in store.entries { store.deleteEntry(entry.id) }
        store.addEntry(country: "Peru", kind: .coin, denomination: "1 Sol", year: "2015", condition: .fine, note: "", photoData: nil, faceValueUSD: 0.27, isPro: false)
        let entry = store.entries[0]
        store.updateEntry(entry.id, country: "Peru", kind: .bill, denomination: "10 Soles", year: "2018", condition: .mint, note: "Market stall", photoData: nil, faceValueUSD: 2.70)
        let updated = store.entries[0]
        XCTAssertEqual(updated.kind, .bill)
        XCTAssertEqual(updated.denomination, "10 Soles")
        XCTAssertEqual(updated.condition, .mint)
        XCTAssertEqual(updated.faceValueUSD, 2.70, accuracy: 0.001)
    }

    func testDeleteEntryRemovesIt() {
        let store = TenderStore()
        for entry in store.entries { store.deleteEntry(entry.id) }
        store.addEntry(country: "Chile", kind: .coin, denomination: "100 Pesos", year: "2019", condition: .fine, note: "", photoData: nil, faceValueUSD: 0.11, isPro: false)
        let id = store.entries[0].id
        store.deleteEntry(id)
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testTotalFaceValueUSDSumsAllEntries() {
        let store = TenderStore()
        for entry in store.entries { store.deleteEntry(entry.id) }
        store.addEntry(country: "Japan", kind: .coin, denomination: "100 Yen", year: "2019", condition: .fine, note: "", photoData: nil, faceValueUSD: 0.68, isPro: false)
        store.addEntry(country: "France", kind: .bill, denomination: "10 Euro", year: "2017", condition: .mint, note: "", photoData: nil, faceValueUSD: 10.80, isPro: false)
        XCTAssertEqual(store.totalFaceValueUSD, 11.48, accuracy: 0.001)
    }

    func testCoveredContinentsReflectsLoggedCountries() {
        let store = TenderStore()
        for entry in store.entries { store.deleteEntry(entry.id) }
        store.addEntry(country: "Japan", kind: .coin, denomination: "100 Yen", year: "2019", condition: .fine, note: "", photoData: nil, faceValueUSD: 0.68, isPro: false)
        store.addEntry(country: "France", kind: .bill, denomination: "10 Euro", year: "2017", condition: .mint, note: "", photoData: nil, faceValueUSD: 10.80, isPro: false)
        XCTAssertEqual(store.coveredContinents, Set([.asia, .europe]))
    }

    func testDuplicateCountryCountDetectsRepeats() {
        let store = TenderStore()
        for entry in store.entries { store.deleteEntry(entry.id) }
        store.addEntry(country: "Japan", kind: .coin, denomination: "100 Yen", year: "2019", condition: .fine, note: "", photoData: nil, faceValueUSD: 0.68, isPro: false)
        store.addEntry(country: "Japan", kind: .coin, denomination: "500 Yen", year: "2020", condition: .fine, note: "", photoData: nil, faceValueUSD: 3.40, isPro: false)
        XCTAssertEqual(store.duplicateCountryCount(for: "Japan"), 2)
        XCTAssertEqual(store.duplicateCountryCount(for: "japan"), 2)
    }
}
