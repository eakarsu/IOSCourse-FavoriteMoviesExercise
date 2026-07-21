import CoreData
import UIKit

@objc(Movie)
final class Movie: NSManagedObject {
    func setMovieImage(_ image: UIImage?) { imdbImage = image?.jpegData(compressionQuality: 0.82) }
    func getMovieImage() -> UIImage? { imdbImage.flatMap(UIImage.init(data:)) }
}
