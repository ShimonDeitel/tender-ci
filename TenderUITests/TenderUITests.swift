import XCTest

final class TenderUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testAddEntryFromMainList() throws {
        let app = launchApp()

        let addButton = app.buttons["addEntryButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let countryField = app.textFields["countryField"]
        XCTAssertTrue(countryField.waitForExistence(timeout: 5), "New Entry sheet did not appear")
        countryField.tap()
        countryField.typeText("Thailand")

        let denomField = app.textFields["denominationField"]
        denomField.tap()
        denomField.typeText("20 Baht")

        let saveButton = app.buttons["entrySaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Thailand"].waitForExistence(timeout: 5), "New entry did not appear on the list")
    }

    func testFreeLimitTriggersPaywallAfterFifteenEntries() throws {
        let app = launchApp()
        // Seed data already has 2 entries; add 13 more to reach the free cap
        // of 15, then a 16th to genuinely overflow past the cap.
        for i in 1...14 {
            let addButton = app.buttons["addEntryButton"]
            addButton.tap()
            let countryField = app.textFields["countryField"]
            if countryField.waitForExistence(timeout: 3) {
                countryField.tap()
                countryField.typeText("Country\(i)")
                let denomField = app.textFields["denominationField"]
                denomField.tap()
                denomField.typeText("1 Unit")
                app.buttons["entrySaveButton"].tap()
            }
        }
        XCTAssertTrue(app.staticTexts["Tender Pro"].waitForExistence(timeout: 5), "Paywall did not appear after hitting the free entry limit")
    }

    func testSimulatedPurchaseUnlocksUnlimitedEntries() throws {
        let app = launchApp()
        for i in 1...14 {
            let addButton = app.buttons["addEntryButton"]
            addButton.tap()
            let countryField = app.textFields["countryField"]
            if countryField.waitForExistence(timeout: 3) {
                countryField.tap()
                countryField.typeText("Country\(i)")
                let denomField = app.textFields["denominationField"]
                denomField.tap()
                denomField.typeText("1 Unit")
                app.buttons["entrySaveButton"].tap()
            }
        }
        XCTAssertTrue(app.staticTexts["Tender Pro"].waitForExistence(timeout: 5))

        let unlockButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Unlock'")).firstMatch
        XCTAssertTrue(unlockButton.waitForExistence(timeout: 5))
        unlockButton.tap()

        let confirmButton = app.buttons["Subscribe"].exists ? app.buttons["Subscribe"] : app.buttons["Buy"]
        if confirmButton.waitForExistence(timeout: 5) {
            confirmButton.tap()
        }

        XCTAssertTrue(app.staticTexts["Tender Pro unlocked"].waitForExistence(timeout: 10) || app.buttons["addEntryButton"].waitForExistence(timeout: 10))

        let addButton = app.buttons["addEntryButton"]
        if addButton.waitForExistence(timeout: 5) {
            var tapped = false
            for _ in 0..<16 {
                if addButton.isHittable {
                    addButton.tap()
                    tapped = true
                    break
                }
                Thread.sleep(forTimeInterval: 0.5)
            }
            if !tapped {
                addButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            let countryField = app.textFields["countryField"]
            if countryField.waitForExistence(timeout: 5) {
                countryField.tap()
                countryField.typeText("FinalCountry")
                let denomField = app.textFields["denominationField"]
                denomField.tap()
                denomField.typeText("1 Unit")
                app.buttons["entrySaveButton"].tap()
                XCTAssertTrue(app.staticTexts["FinalCountry"].waitForExistence(timeout: 5))
            }
        }
    }

    func testEditEntryFromSettings() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        let editButton = app.buttons.matching(identifier: "editEntry_Japan_100 Yen").firstMatch
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let countryField = app.textFields["countryField"]
        XCTAssertTrue(countryField.waitForExistence(timeout: 5))
        countryField.tap()
        let stringValue = countryField.value as? String ?? ""
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        countryField.typeText(deleteString)
        countryField.typeText("South Korea")

        app.buttons["entrySaveButton"].tap()

        XCTAssertTrue(app.staticTexts["South Korea"].waitForExistence(timeout: 5), "Country rename did not apply")
    }

    func testDeleteEntryViaSwipe() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        app.buttons["settingsAddEntryButton"].tap()
        let countryField = app.textFields["countryField"]
        XCTAssertTrue(countryField.waitForExistence(timeout: 5))
        countryField.tap()
        countryField.typeText("Disposable Country")
        let denomField = app.textFields["denominationField"]
        denomField.tap()
        denomField.typeText("1 Unit")
        app.buttons["entrySaveButton"].tap()
        XCTAssertTrue(app.staticTexts["Disposable Country"].waitForExistence(timeout: 5))

        app.staticTexts["Disposable Country"].swipeLeft()

        let deleteButton = app.buttons["deleteEntrySwipe_Disposable Country_1 Unit"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Swipe-to-delete action did not appear")
        deleteButton.tap()

        XCTAssertFalse(app.staticTexts["Disposable Country"].waitForExistence(timeout: 3), "Entry was not deleted")
    }

    func testKeyboardDismissesOnTapOutside() throws {
        let app = launchApp()
        let addButton = app.buttons["addEntryButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let countryField = app.textFields["countryField"]
        XCTAssertTrue(countryField.waitForExistence(timeout: 5))
        countryField.tap()
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 5), "Keyboard did not appear")

        // Tap a real Form section header/label (not nav bar chrome) to
        // trigger the dismissKeyboardOnTap gesture attached to the Form.
        app.staticTexts["Currency"].tap()

        let keyboardGone = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: keyboardGone, object: app.keyboards.element)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "Keyboard did not dismiss after tapping outside the text field")
    }
}
