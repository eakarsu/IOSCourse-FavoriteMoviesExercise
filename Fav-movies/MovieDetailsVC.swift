import UIKit

final class MovieDetailsVC: UIViewController {
    private var movie: FavoriteMovieRecord?
    @IBOutlet private weak var imdbImage: UIImageView!
    @IBOutlet private weak var movieTitle: UITextField!
    @IBOutlet private weak var imdbURL: UITextField!
    @IBOutlet private weak var myDescription: UITextView!
    @IBOutlet private weak var imdbPlotDescription: UITextView!

    func configure(movie: FavoriteMovieRecord) { self.movie = movie }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let movie else {
            view.accessibilityIdentifier = "movie.details.error"
            return
        }
        imdbPlotDescription.text = movie.plotDescription
        imdbImage.image = movie.imageData.flatMap(UIImage.init(data:))
        movieTitle.text = movie.title
        imdbURL.text = movie.imdbURL
        myDescription.text = movie.personalDescription
        [movieTitle, imdbURL].forEach { $0?.isUserInteractionEnabled = false }
        [myDescription, imdbPlotDescription].forEach { $0?.isEditable = false; $0?.adjustsFontForContentSizeCategory = true }
        movieTitle.accessibilityIdentifier = "movie.details.title"
        imdbURL.accessibilityIdentifier = "movie.details.url"
        myDescription.accessibilityIdentifier = "movie.details.personalDescription"
        imdbPlotDescription.accessibilityIdentifier = "movie.details.plot"
        view.accessibilityIdentifier = "movie.details.offline"
        navigationItem.title = movie.title
    }
}
