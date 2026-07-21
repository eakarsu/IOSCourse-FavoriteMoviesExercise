// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FavoriteMoviesCore",
    platforms: [.macOS(.v13), .iOS(.v15)],
    products: [.library(name: "FavoriteMoviesCore", targets: ["FavoriteMoviesCore"])],
    targets: [
        .target(name: "FavoriteMoviesCore"),
        .testTarget(name: "FavoriteMoviesCoreTests", dependencies: ["FavoriteMoviesCore"])
    ]
)
