# Release runbook

1. Run `scripts/verify.sh` on a machine with a compatible iOS simulator runtime, including the in-memory Core Data integration tests and five UI journeys.
2. Test an upgrade from a copy of the original 2015 SQLite store and verify row counts, identifiers, text, and images before and after migration.
3. Set an organization-owned bundle identifier and development team; never commit certificates or provisioning profiles.
4. Increment marketing/build versions, archive/analyze Release, and validate the archive.
5. Supply owner-approved final App Store icons and capture screenshots for empty, list, add, validation, details, portrait/landscape, and accessibility sizes. The current catalog lacks approved final icon binaries.
6. Test VoiceOver, Switch Control, Dynamic Type, rotation, photo permission denial, interruption/restoration, low storage, migration failure, and swipe deletion on supported devices.
7. Confirm privacy manifest/App Store answers against the final binary and obtain product/release approval.
