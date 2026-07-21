import CoreData
import Foundation

extension Movie {
    @NSManaged var id: UUID?
    @NSManaged var createdAt: Date?
    @NSManaged var schemaVersion: Int16
    @NSManaged var movieTitle: String?
    @NSManaged var imdbURL: String?
    @NSManaged var myDescription: String?
    @NSManaged var imdbPlotDescription: String?
    @NSManaged var imdbImage: Data?
}
