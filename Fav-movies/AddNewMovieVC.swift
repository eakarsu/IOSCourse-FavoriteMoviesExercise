import UIKit

final class AddNewMovieVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet private weak var movieTitle: UITextField!
    @IBOutlet private weak var imdbURL: UITextField!
    @IBOutlet private weak var myDescription: UITextField!
    @IBOutlet private weak var imdbPlotDescription: UITextField!
    @IBOutlet private weak var imdbImage: UIImageView!
    @IBOutlet private weak var addMovieButton: UIButton!
    private let imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imdbImage.image = nil
        imdbImage.layer.cornerRadius = 4
        imdbImage.clipsToBounds = true
        configure(movieTitle, id: "movie.title", labelKey: "field.title")
        configure(imdbURL, id: "movie.url", labelKey: "field.url")
        configure(myDescription, id: "movie.personalDescription", labelKey: "field.personalDescription")
        configure(imdbPlotDescription, id: "movie.plot", labelKey: "field.plot")
        addMovieButton.accessibilityIdentifier = "movie.save"
        addMovieButton.accessibilityLabel = NSLocalizedString("button.saveMovie", comment: "Save")
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage { imdbImage.image = image }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }

    @IBAction private func addImage(_ sender: AnyObject) { present(imagePicker, animated: true) }

    @IBAction private func createMovie(_ sender: AnyObject) {
        view.endEditing(true)
        let draft = FavoriteMovieDraft(
            title: movieTitle.text ?? "",
            imdbURL: imdbURL.text ?? "",
            personalDescription: myDescription.text ?? "",
            plotDescription: imdbPlotDescription.text ?? ""
        )
        let imageData = imdbImage.image?.jpegData(compressionQuality: 0.82)
        guard let app = UIApplication.shared.delegate as? AppDelegate, app.persistenceError == nil else {
            return showError(key: "error.persistence")
        }
        do {
            _ = try app.movieRepository.create(draft: draft, imageData: imageData)
            navigationController?.popViewController(animated: true)
        } catch let error as FavoriteMovieValidationError {
            showError(key: "error.\(error.rawValue)")
        } catch {
            showError(key: "error.persistence")
        }
    }

    private func configure(_ field: UITextField, id: String, labelKey: String) {
        field.accessibilityIdentifier = id
        field.accessibilityLabel = NSLocalizedString(labelKey, comment: "Movie field")
        field.clearButtonMode = .whileEditing
        field.autocorrectionType = .no
    }

    private func showError(key: String) {
        let message = NSLocalizedString(key, comment: "Movie error")
        let alert = UIAlertController(title: NSLocalizedString("error.title", comment: "Error"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("button.ok", comment: "OK"), style: .default))
        present(alert, animated: true)
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
