import XCTest

final class FavoriteMoviesJourneyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-reset-favorite-movies"]
    }

    func testEmptyOfflineLibraryAndValidationError() {
        app.launch()
        XCTAssertEqual(app.staticTexts["movies.status"].value as? String, "No favorite movies yet. Add one to begin. Everything works offline.")
        app.buttons["movies.new"].tap()
        app.buttons["movie.save"].tap()
        XCTAssertTrue(app.alerts["Movie not saved"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Enter a movie title."].exists)
    }

    func testCreateAndOpenPrimaryJourney() {
        app.launch(); addMovie(title: "Arrival")
        XCTAssertEqual(app.cells.count, 1)
        app.cells.element(boundBy: 0).tap()
        XCTAssertEqual(app.textFields["movie.details.title"].value as? String, "Arrival")
    }

    func testLocalPersistenceRestoresAfterRelaunch() {
        app.launch(); addMovie(title: "Moon")
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertEqual(app.cells.count, 1)
        XCTAssertTrue(app.cells.element(boundBy: 0).label.contains("Moon"))
    }

    func testMalformedLegacyMovieIsRecovered() {
        app.launchArguments = ["-inject-malformed-favorite-movie"]
        app.launch()
        XCTAssertEqual(app.cells.count, 1)
        XCTAssertTrue(app.cells.element(boundBy: 0).label.contains("Untitled movie"))
    }

    func testRotationAndLocalizationKeepLibraryUsable() {
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.tables["movies.list"].waitForExistence(timeout: 2))
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["movies.new"].isHittable)
    }

    private func addMovie(title: String) {
        app.buttons["movies.new"].tap()
        let field = app.textFields["movie.title"]
        field.tap(); field.typeText(title)
        app.buttons["movie.save"].tap()
        XCTAssertTrue(app.tables["movies.list"].waitForExistence(timeout: 2))
    }
}
