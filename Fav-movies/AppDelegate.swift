import CoreData
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private(set) var persistenceError: Error?

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Fav_movies")
        for description in container.persistentStoreDescriptions {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores { [weak self] _, error in self?.persistenceError = error }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    lazy var movieRepository = CoreDataMovieRepository(container: persistentContainer)

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        _ = persistentContainer
        applyUITestLaunchState()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) { saveContext() }
    func applicationWillTerminate(_ application: UIApplication) { saveContext() }

    func saveContext() {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return }
        do { try context.save() } catch { persistenceError = error; context.rollback() }
    }

    private func applyUITestLaunchState() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-reset-favorite-movies") { try? movieRepository.deleteAll() }
        if arguments.contains("-inject-malformed-favorite-movie") {
            try? movieRepository.deleteAll()
            let object = NSEntityDescription.insertNewObject(forEntityName: "Movie", into: persistentContainer.viewContext)
            object.setValue("   ", forKey: "movieTitle")
            try? persistentContainer.viewContext.save()
        }
    }
}
