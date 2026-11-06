# PinFan data and website

This repository hosts PinFan's database and the website in [`docs/`](docs/).
The database is produced and published by the separately hosted scraper.

- `pinside_database.db` and `pinside_database.json`: the machine catalog.
- `version.json`: catalog version and integrity information used by the app.
- `pinside_details_cache.json`, `quality_report.json`, and `scrape_status.json`:
  data used to maintain and report on the published catalog.
- `docs/`: the GitHub Pages website.

Catalog information is sourced from [Pinside](https://pinside.com/).
