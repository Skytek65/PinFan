# PinFan

Neon arcade iOS companion for pinball fans — browse ~3,195 machines, track your collection, and log high scores offline.

| | |
|---|---|
| **Bundle** | `com.skytek.PinFan` |
| **Version** | 1.0 (build 1) |
| **Minimum iOS** | 17.0 |
| **Repo** | https://github.com/Skytek65/PinFan |

## Features

- **Home** — featured cabinets, stats, trivia, random machine
- **Explore** — browse/search ~3,195 Pinside-sourced machines (ratings, makers, years, specs)
- **My Arcade** — favorites, owned machines, notes, high-score logging
- **Offline** — on-device SQLite DB with GitHub-hosted sync/updates

## Marketing site (GitHub Pages)

The public landing page lives in [`docs/`](docs/).

To enable Pages:

1. **Settings → Pages**
2. **Deploy from a branch**
3. Branch: **`main`**, folder: **`/docs`**

Site URL (default): https://skytek65.github.io/PinFan/

See also [`docs/README.md`](docs/README.md) and [`APP_STORE_LISTING.md`](APP_STORE_LISTING.md) for App Store Connect copy.

## iOS app

Open `PinFan/PinFan.xcodeproj` in Xcode. Requires iOS 17.0+.

Catalog data is sourced from [Pinside](https://pinside.com/).
