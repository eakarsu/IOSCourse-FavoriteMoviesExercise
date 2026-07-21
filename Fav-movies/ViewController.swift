import UIKit

final class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private enum ViewState { case loading, emptyOffline, contentOffline, error }
    @IBOutlet private weak var movieTableView: UITableView!
    private var movies: [FavoriteMovieRecord] = []
    private let statusLabel = UILabel()

    private var appDelegate: AppDelegate? { UIApplication.shared.delegate as? AppDelegate }

    override func viewDidLoad() {
        super.viewDidLoad()
        movieTableView.delegate = self
        movieTableView.dataSource = self
        movieTableView.accessibilityIdentifier = "movies.list"
        movieTableView.refreshControl = UIRefreshControl()
        movieTableView.refreshControl?.addTarget(self, action: #selector(reloadMovies), for: .valueChanged)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.accessibilityIdentifier = "movies.status"
        navigationItem.accessibilityLabel = NSLocalizedString("movies.navigation", comment: "Movies navigation")
        navigationItem.rightBarButtonItem?.customView?.accessibilityIdentifier = "movies.new"
        navigationItem.rightBarButtonItem?.customView?.accessibilityLabel = NSLocalizedString("button.newMovie", comment: "New movie")
        apply(.loading)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadMovies()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "cellSubmitSegue",
              let cell = sender as? UITableViewCell,
              let indexPath = movieTableView.indexPath(for: cell),
              movies.indices.contains(indexPath.row),
              let details = segue.destination as? MovieDetailsVC else { return }
        let movie = movies[indexPath.row]
        details.configure(movie: movie)
        UserDefaults.standard.set(movie.id.uuidString, forKey: "favoriteMovies.lastSelection.v1")
    }

    @objc private func reloadMovies() {
        apply(.loading)
        defer { movieTableView.refreshControl?.endRefreshing() }
        guard let appDelegate, appDelegate.persistenceError == nil else { apply(.error); return }
        do {
            movies = try appDelegate.movieRepository.fetch()
            movieTableView.reloadData()
            apply(movies.isEmpty ? .emptyOffline : .contentOffline)
        } catch {
            movies = []; movieTableView.reloadData(); apply(.error)
        }
    }

    private func apply(_ state: ViewState) {
        switch state {
        case .loading:
            view.accessibilityIdentifier = "movies.loading"
            statusLabel.text = NSLocalizedString("movies.loading", comment: "Loading")
            movieTableView.backgroundView = statusLabel
        case .emptyOffline:
            view.accessibilityIdentifier = "movies.empty.offline"
            statusLabel.text = NSLocalizedString("movies.empty", comment: "Empty")
            movieTableView.backgroundView = statusLabel
        case .contentOffline:
            view.accessibilityIdentifier = "movies.content.offline"
            movieTableView.backgroundView = nil
        case .error:
            view.accessibilityIdentifier = "movies.error"
            statusLabel.text = NSLocalizedString("movies.error", comment: "Load error")
            movieTableView.backgroundView = statusLabel
            UIAccessibility.post(notification: .announcement, argument: statusLabel.text)
        }
        statusLabel.accessibilityValue = statusLabel.text
    }

    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { movies.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as? MovieCell else {
            return UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        }
        cell.configure(movie: movies[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, movies.indices.contains(indexPath.row), let appDelegate else { return }
        do {
            try appDelegate.movieRepository.delete(id: movies[indexPath.row].id)
            movies.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            apply(movies.isEmpty ? .emptyOffline : .contentOffline)
        } catch { apply(.error) }
    }
}
