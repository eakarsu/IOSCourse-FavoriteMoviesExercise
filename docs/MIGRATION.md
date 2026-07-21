# Core Data migration policy

The existing `Movie` entity remains the durable store boundary. The current additive schema adds optional `id`, `createdAt`, and `schemaVersion` attributes, allowing lightweight migration from the 2015 store. Automatic migration and inferred mappings are enabled in `AppDelegate`.

On the first repository fetch, legacy rows receive an identifier, creation timestamp, and schema version. Missing text and images are read safely; blank legacy titles display as “Untitled movie.” No destructive reset or seed runs at startup. Repository tests use an isolated in-memory Core Data store to cover create/fetch/delete, deterministic reset, legacy backfill, malformed records, sorting, and validation.

Any future incompatible schema change must add a new model version, a mapping or staged migration, fixture-based upgrade tests, backup/restore instructions, and an explicit rollback decision before release.
