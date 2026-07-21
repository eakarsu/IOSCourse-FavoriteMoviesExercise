import CoreData
import XCTest
@testable import FavoriteMoviesCore

final class FavoriteMoviesRepositoryTests: XCTestCase {
    func testMissingTitleIsRejected() { XCTAssertThrowsError(try FavoriteMovieDraft(title: " ").validated()) }
    func testLongTitleIsRejected() { XCTAssertThrowsError(try FavoriteMovieDraft(title: String(repeating: "x", count: 121)).validated()) }
    func testInvalidURLIsRejected() { XCTAssertThrowsError(try FavoriteMovieDraft(title: "Alien", imdbURL: "javascript:alert(1)").validated()) }
    func testHTTPSURLAndWhitespaceAreNormalized() throws {
        let draft = try FavoriteMovieDraft(title: " Alien ", imdbURL: " https://www.imdb.com/title/tt0078748/ ").validated()
        XCTAssertEqual(draft.title, "Alien"); XCTAssertEqual(draft.imdbURL, "https://www.imdb.com/title/tt0078748/")
    }
    func testOversizeDescriptionsAreRejected() {
        XCTAssertThrowsError(try FavoriteMovieDraft(title: "A", personalDescription: String(repeating: "x", count: 1_001)).validated())
        XCTAssertThrowsError(try FavoriteMovieDraft(title: "A", plotDescription: String(repeating: "x", count: 5_001)).validated())
    }
    func testOversizeImageIsRejected() { XCTAssertThrowsError(try FavoriteMovieDraft(title: "A").validated(imageByteCount: 10 * 1_024 * 1_024 + 1)) }

    func testCreateAndFetchRoundTrip() throws {
        let repository = makeRepository()
        let created = try repository.create(draft: FavoriteMovieDraft(title: "Arrival", imdbURL: "https://imdb.com/title/tt2543164", personalDescription: "Favorite", plotDescription: "First contact"), imageData: Data([1, 2, 3]))
        XCTAssertEqual(try repository.fetch(), [created])
    }

    func testNewestMoviesSortFirst() throws {
        var date = Date(timeIntervalSince1970: 1)
        let repository = makeRepository(now: { defer { date.addTimeInterval(1) }; return date })
        _ = try repository.create(draft: FavoriteMovieDraft(title: "First"), imageData: nil)
        _ = try repository.create(draft: FavoriteMovieDraft(title: "Second"), imageData: nil)
        XCTAssertEqual(try repository.fetch().map(\.title), ["Second", "First"])
    }

    func testDeleteRemovesOnlyRequestedMovie() throws {
        let repository = makeRepository()
        let keep = try repository.create(draft: FavoriteMovieDraft(title: "Keep"), imageData: nil)
        let remove = try repository.create(draft: FavoriteMovieDraft(title: "Remove"), imageData: nil)
        try repository.delete(id: remove.id)
        XCTAssertEqual(try repository.fetch().map(\.id), [keep.id])
    }

    func testDeletingUnknownIDIsIdempotent() throws {
        let repository = makeRepository(); try repository.delete(id: UUID()); XCTAssertEqual(try repository.fetch(), [])
    }

    func testLegacyRecordIsBackfilledDuringMigration() throws {
        let container = makeContainer(); let context = container.viewContext
        let object = NSEntityDescription.insertNewObject(forEntityName: "Movie", into: context)
        object.setValue("Legacy", forKey: "movieTitle"); try context.save()
        let record = try CoreDataMovieRepository(container: container, now: { Date(timeIntervalSince1970: 10) }).fetch().first
        XCTAssertEqual(record?.title, "Legacy"); XCTAssertEqual(record?.createdAt, Date(timeIntervalSince1970: 10)); XCTAssertNotNil(record?.id)
    }

    func testMalformedLegacyTitleUsesSafePlaceholder() throws {
        let container = makeContainer(); let object = NSEntityDescription.insertNewObject(forEntityName: "Movie", into: container.viewContext)
        object.setValue("  ", forKey: "movieTitle"); try container.viewContext.save()
        XCTAssertEqual(try CoreDataMovieRepository(container: container).fetch().first?.title, "Untitled movie")
    }

    func testDuplicateTitlesRemainDistinctRecords() throws {
        let repository = makeRepository()
        let one = try repository.create(draft: FavoriteMovieDraft(title: "Dune"), imageData: nil)
        let two = try repository.create(draft: FavoriteMovieDraft(title: "Dune"), imageData: nil)
        XCTAssertNotEqual(one.id, two.id); XCTAssertEqual(try repository.fetch().count, 2)
    }

    func testDeleteAllSupportsDeterministicReset() throws {
        let repository = makeRepository(); _ = try repository.create(draft: FavoriteMovieDraft(title: "One"), imageData: nil)
        _ = try repository.create(draft: FavoriteMovieDraft(title: "Two"), imageData: nil)
        try repository.deleteAll(); XCTAssertEqual(try repository.fetch(), [])
    }

    private func makeRepository(now: @escaping () -> Date = Date.init) -> CoreDataMovieRepository {
        CoreDataMovieRepository(container: makeContainer(), now: now)
    }

    private func makeContainer() -> NSPersistentContainer {
        let model = NSManagedObjectModel(); let entity = NSEntityDescription(); entity.name = "Movie"; entity.managedObjectClassName = "NSManagedObject"
        entity.properties = [
            attribute("id", .UUIDAttributeType), attribute("createdAt", .dateAttributeType), attribute("schemaVersion", .integer16AttributeType),
            attribute("movieTitle", .stringAttributeType), attribute("imdbURL", .stringAttributeType), attribute("myDescription", .stringAttributeType),
            attribute("imdbPlotDescription", .stringAttributeType), attribute("imdbImage", .binaryDataAttributeType)
        ]
        model.entities = [entity]
        let container = NSPersistentContainer(name: "FavoriteMoviesTests", managedObjectModel: model)
        let description = NSPersistentStoreDescription(); description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        var loadError: Error?; container.loadPersistentStores { _, error in loadError = error }
        XCTAssertNil(loadError)
        return container
    }

    private func attribute(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
        let attribute = NSAttributeDescription(); attribute.name = name; attribute.attributeType = type; attribute.isOptional = true; return attribute
    }
}
