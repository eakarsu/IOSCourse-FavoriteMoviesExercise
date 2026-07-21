import UIKit

final class MovieCell: UITableViewCell {
    @IBOutlet private weak var imdbImage: UIImageView!
    @IBOutlet private weak var movieTitle: UITextField!
    @IBOutlet private weak var imdbURL: UITextField!
    @IBOutlet private weak var myDescription: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        [movieTitle, imdbURL, myDescription].forEach { $0?.isUserInteractionEnabled = false }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    func configure(movie: FavoriteMovieRecord) {
        movieTitle.text = movie.title
        imdbURL.text = movie.imdbURL
        myDescription.text = movie.personalDescription
        imdbImage.image = movie.imageData.flatMap(UIImage.init(data:))
        accessibilityIdentifier = "movie.row.\(movie.id.uuidString)"
        accessibilityLabel = [movie.title, movie.personalDescription].filter { !$0.isEmpty }.joined(separator: ". ")
    }
}
