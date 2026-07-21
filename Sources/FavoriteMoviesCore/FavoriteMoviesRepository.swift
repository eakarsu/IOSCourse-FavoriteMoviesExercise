import CoreData
import Foundation

public enum FavoriteMovieValidationError: String, Error, Equatable {
    case missingTitle
    case titleTooLong
    case invalidURL
    case descriptionTooLong
    case plotTooLong
    case imageTooLarge
}

public enum FavoriteMoviesStoreError: Error, Equatable {
    case missingEntity
    case saveFailed
}

public struct FavoriteMovieDraft: Equatable {
    public var title: String
    public var imdbURL: String
    public var personalDescription: String
    public var plotDescription: String

    public init(title: String, imdbURL: String = "", personalDescription: String = "", plotDescription: String = "") {
        self.title = title
        self.imdbURL = imdbURL
        self.personalDescription = personalDescription
        self.plotDescription = plotDescription
    }

    public func validated(imageByteCount: Int = 0) throws -> FavoriteMovieDraft {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw FavoriteMovieValidationError.missingTitle }
        guard trimmedTitle.count <= 120 else { throw FavoriteMovieValidationError.titleTooLong }
        guard personalDescription.count <= 1_000 else { throw FavoriteMovieValidationError.descriptionTooLong }
        guard plotDescription.count <= 5_000 else { throw FavoriteMovieValidationError.plotTooLong }
        guard imageByteCount <= 10 * 1_024 * 1_024 else { throw FavoriteMovieValidationError.imageTooLarge }
        let trimmedURL = imdbURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedURL.isEmpty {
            guard let components = URLComponents(string: trimmedURL),
                  ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
                  components.host?.isEmpty == false else {
                throw FavoriteMovieValidationError.invalidURL
            }
        }
        return FavoriteMovieDraft(
            title: trimmedTitle,
            imdbURL: trimmedURL,
            personalDescription: personalDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            plotDescription: plotDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

public struct FavoriteMovieRecord: Equatable, Identifiable {
    public let id: UUID
    public let createdAt: Date
    public let title: String
    public let imdbURL: String
    public let personalDescription: String
    public let plotDescription: String
    public let imageData: Data?

    public init(id: UUID, createdAt: Date, title: String, imdbURL: String, personalDescription: String, plotDescription: String, imageData: Data?) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.imdbURL = imdbURL
        self.personalDescription = personalDescription
        self.plotDescription = plotDescription
        self.imageData = imageData
    }
}

public final class CoreDataMovieRepository {
    private let container: NSPersistentContainer
    private let entityName: String
    private let now: () -> Date

    public init(container: NSPersistentContainer, entityName: String = "Movie", now: @escaping () -> Date = Date.init) {
        self.container = container
        self.entityName = entityName
        self.now = now
    }

    public func fetch() throws -> [FavoriteMovieRecord] {
        try perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            let objects = try self.container.viewContext.fetch(request)
            var changed = false
            let records = objects.map { object -> FavoriteMovieRecord in
                if object.value(forKey: "id") as? UUID == nil { object.setValue(UUID(), forKey: "id"); changed = true }
                if object.value(forKey: "createdAt") as? Date == nil { object.setValue(self.now(), forKey: "createdAt"); changed = true }
                if (object.value(forKey: "schemaVersion") as? NSNumber)?.int16Value != 1 { object.setValue(1, forKey: "schemaVersion"); changed = true }
                return self.record(from: object)
            }
            if changed { try self.container.viewContext.save() }
            return records.sorted { $0.createdAt > $1.createdAt }
        }
    }

    @discardableResult
    public func create(draft: FavoriteMovieDraft, imageData: Data?) throws -> FavoriteMovieRecord {
        let validated = try draft.validated(imageByteCount: imageData?.count ?? 0)
        return try perform {
            guard let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: self.container.viewContext) else {
                throw FavoriteMoviesStoreError.missingEntity
            }
            let object = NSManagedObject(entity: entity, insertInto: self.container.viewContext)
            object.setValue(UUID(), forKey: "id")
            object.setValue(self.now(), forKey: "createdAt")
            object.setValue(1, forKey: "schemaVersion")
            object.setValue(validated.title, forKey: "movieTitle")
            object.setValue(validated.imdbURL, forKey: "imdbURL")
            object.setValue(validated.personalDescription, forKey: "myDescription")
            object.setValue(validated.plotDescription, forKey: "imdbPlotDescription")
            object.setValue(imageData, forKey: "imdbImage")
            try self.container.viewContext.save()
            return self.record(from: object)
        }
    }

    public func delete(id: UUID) throws {
        try perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            if let object = try self.container.viewContext.fetch(request).first {
                self.container.viewContext.delete(object)
                try self.container.viewContext.save()
            }
        }
    }

    public func deleteAll() throws {
        try perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
            for object in try self.container.viewContext.fetch(request) { self.container.viewContext.delete(object) }
            if self.container.viewContext.hasChanges { try self.container.viewContext.save() }
        }
    }

    private func record(from object: NSManagedObject) -> FavoriteMovieRecord {
        let rawTitle = (object.value(forKey: "movieTitle") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return FavoriteMovieRecord(
            id: object.value(forKey: "id") as? UUID ?? UUID(),
            createdAt: object.value(forKey: "createdAt") as? Date ?? now(),
            title: rawTitle?.isEmpty == false ? rawTitle! : "Untitled movie",
            imdbURL: object.value(forKey: "imdbURL") as? String ?? "",
            personalDescription: object.value(forKey: "myDescription") as? String ?? "",
            plotDescription: object.value(forKey: "imdbPlotDescription") as? String ?? "",
            imageData: object.value(forKey: "imdbImage") as? Data
        )
    }

    private func perform<T>(_ work: () throws -> T) throws -> T {
        var result: Result<T, Error>!
        container.viewContext.performAndWait { result = Result { try work() } }
        return try result.get()
    }
}
