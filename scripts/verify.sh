#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
swift test
plutil -lint Fav-movies/Info.plist Fav-movies/PrivacyInfo.xcprivacy Fav-movies/en.lproj/Localizable.strings Fav-movies.xcodeproj/project.pbxproj
xmllint --noout Fav-movies/Base.lproj/Main.storyboard Fav-movies/Fav_movies.xcdatamodeld/Fav_movies.xcdatamodel/contents Fav-movies.xcodeproj/xcshareddata/xcschemes/Fav-movies.xcscheme
ibtool --errors --warnings --notices --minimum-deployment-target 15.0 Fav-movies/Base.lproj/Main.storyboard >/dev/null
favorite_movies_destination="${IOS_FAVORITE_MOVIES_DESTINATION:-platform=iOS Simulator,name=iPhone 16 Pro}"
xcodebuild -project Fav-movies.xcodeproj -scheme Fav-movies -destination "$favorite_movies_destination" -configuration Debug CODE_SIGNING_ALLOWED=NO test
xcodebuild -project Fav-movies.xcodeproj -scheme Fav-movies -sdk iphonesimulator -configuration Release CODE_SIGNING_ALLOWED=NO analyze
