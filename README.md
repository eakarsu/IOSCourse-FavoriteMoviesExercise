# Favorite Movies

An offline iOS favorite-movie library backed by a lightweight-migrated Core Data store. The project includes validated domain/repository tests, five UI journeys, privacy and release documentation, and a shared CI scheme. See `docs/RELEASE.md` before shipping.

The root `start.sh` launches a loopback-only runtime-verification companion; it does not replace or launch the native UIKit application. The companion provides a functional credential login/identity/AI-review UI on its assigned UI port and persists hashed sessions plus append-only provider evidence in an isolated PostgreSQL database. Its ignored `.env` must use the approved OpenRouter key/model and canonical API base.
