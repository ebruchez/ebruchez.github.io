# AGENTS.md — Guide for `bruchez.name`

Personal blog and collection site for Erik Bruchez (`https://blog.bruchez.name`), built with **Jekyll** (`jekyll-theme-chirpy` base, customized) and deployed via GitHub Actions.

## Build & Local Development

- **Production build** (matches `.github/workflows/pages-deploy.yml` — custom Ruby plugins in `_plugins/` are supported in production):
  ```sh
  JEKYLL_ENV=production bundle exec jekyll build --trace
  ```
- **Local dev server**:
  ```sh
  bundle exec jekyll serve
  ```
- **Excluding repo-only files**: Any root-level documentation, scripts, or scratch directories added to the repository **must** be listed under `exclude:` in `_config.yml` so Jekyll does not copy or render them into `_site/`.
- **Node CLI tools**: Default shell `node` via nvm may point to an older version; prepend `/opt/homebrew/bin` (or a modern nvm Node version) to `PATH` if running modern Node CLIs.

---

## Site Architecture & Custom Plugins

- **Layouts & Widths**:
  - `_layouts/home.html` and `_layouts/comics.html` use the full-width `.home-col` container (up to `$main-content-max-width: 1150px`).
  - `_layouts/post.html` and `_layouts/page.html` use the narrower `col-xl-8` column alongside `_includes/panel.html` (right-hand TOC column on posts).
- **Stylesheets**:
  - Entry point: `assets/css/style.scss` → `_sass/jekyll-theme-chirpy.scss` → `_sass/layout/*.scss`.
  - Use theme CSS custom properties (`--card-bg`, `--card-border-color`, `--text-color`, `--text-muted-color`, `--link-color`, `--tb-odd-bg`, `--main-border-color`, `--btn-border-color`) from `_sass/colors/light-typography.scss` and `_sass/colors/dark-typography.scss`.
  - When using CSS Container Queries (`@container`), declare `container: <name> / inline-size` on the **parent** wrapper (e.g. `.comics-card-list` or `.home-tiles-container`), never on the same element being matched inside `@container`.
- **Custom Jekyll Plugins (`_plugins/`)**:
  - `build-speedups.rb`: Indexes relative links in O(1), skips unchanged static asset copies, and precomputes related posts in `:pre_render`. Keep new data/Markdown processing in Ruby `:pre_render` hooks rather than expensive Liquid loops or repeated Liquid `markdownify` filters.
  - `lightbox-images.rb` + `assets/js/lightbox3.min.js`: Automatically wraps content `<img>` tags on `post` and `page` layouts in `<a class="lightbox-trigger" data-lightbox="page-gallery">`. Opt out with `data-no-lightbox` or `.no-lightbox`. On custom layouts (such as `comics`), render `class="lightbox-trigger" data-lightbox="page-gallery"` directly on the `<a>` element (omit legacy `.img-hyperlink`).
  - `comics-data.rb`: Enriches `_data/comics/*.yml` at `:pre_render` time (pre-rendering Markdown, reading `.webp` dimensions to prevent CLS, computing per-year stats, and building `site.data['comics_latest_featured']`).

---

## Comic Books Showcase & Reading Log

### Source of Truth

- **Data files**:
  - Yearly reading logs: `_data/comics/<year>.yml` (`2015.yml` through `2026.yml`, plus new `<YYYY>.yml` files for future years).
  - Curated favorites: `_data/comics_favorites.yml` (`individual_works` and `classics` groups rendered on `/pages/comic-books/`).
- **Pages**:
  - Hub page: `pages/comic-books.md` (`layout: comics` — renders Background, year pill bar, `Latest reads & quick reviews`, and Favorites).
  - Yearly pages: `pages/comic-books-YYYY.md` are thin frontmatter stubs (`layout: comics`, `comics_year: YYYY`). Add or edit comic entries in `_data/comics/YYYY.yml`, **not** in `pages/comic-books-YYYY.md`.
  - When starting a new year (e.g. `2027`), create `_data/comics/2027.yml` and a matching `pages/comic-books-2027.md` frontmatter stub; the year pill bar updates automatically from `_data/comics/*.yml`.
  - Do **not** re-run `tools/migrate-comics-to-yaml.rb` (one-time migration tool) on years whose YAML files have been edited.

### YAML Entry Schema (`_data/comics/YYYY.yml`)

Newest reads go at the **top** of the year's YAML file:

```yaml
- id: series-tome-title              # Unique slug (used for #anchor deep-links & cover filenames)
  read_date: '2026-11-16'            # 'YYYY-MM-DD', 'YYYY-MM', or 'YYYY'
  title: Series - 12. Album Title
  year: 2026                         # Publication year (integer or string like '1964-1965')
  edition: version facsimile         # Optional edition / format note
  language: French                   # Optional (French, English, Italian, German, ...)
  authors:                           # Use `authors` when one creator wrote & drew the album;
    - Single Creator                 # otherwise use `writers` and `artists` (+ optional `colors`)
  writers:
    - Writer Name
  artists:
    - Artist Name
  adapted_from: Original Author      # Optional
  bedetheque_url: https://www.bedetheque.com/BD-...html
  url: https://...                   # Optional non-Bédéthèque publisher/reference URL
  cover: series-tome-title.webp      # Optional filename in assets/pages/comic-books/covers/
  rating: 4                          # Optional 1..5
  reread: false                      # Optional boolean
  featured: true                     # Optional: pins entry to /pages/comic-books/ hub showcase
  review: |-
    Public-facing review / impressions (Markdown supported). Shown openly on the card.
  notes: |-
    Optional plot summary or spoilers (Markdown supported).
    Rendered inside a collapsible <details> ("Plot notes & spoilers") disclosure.
  sub_items:                         # Optional: included tomes/stories for Intégrales & anthologies
    - title: Tome 1. Sub-album Title
      bedetheque_url: https://www.bedetheque.com/BD-...html
      review: |-
        Per-tome notes...
```

### Managing Comic Covers (`tools/manage-comic-covers.rb`)

Covers are stored locally as optimized `.webp` images (`<= 600px` wide) under `assets/pages/comic-books/covers/`. Never hotlink external cover images. Cards without a `cover` adapt automatically to a clean full-width single-column layout via CSS `:has()`.

- **`<entry-id>`**: Refers to the `id:` slug of a comic entry in `_data/comics/YYYY.yml` or `_data/comics_favorites.yml` (e.g. `lefranc-36-la-regate` or `fav-maus` — also used as the card's `#<entry-id>` URL anchor). When passed to `manage-comic-covers.rb` (or used as a filename in `_covers_inbox/`), the script locates that `id:`, converts and resizes the image to `assets/pages/comic-books/covers/<entry-id>.webp`, and writes `cover: <entry-id>.webp` into the matching YAML entry automatically. Run `--status --year YYYY` (or `--status --favorites`) to list all `<entry-id>` values and see which entries are missing covers.

> **Note on `bedetheque.com`**: `www.bedetheque.com` serves a Cloudflare anti-bot challenge (`HTTP 403`) to automated CLI HTTP requests. Never attempt to scrape `bedetheque.com` HTML or bypass challenges; use `--clipboard`, `--inbox`, `--set`, or `--fetch-online` below.

```sh
# Audit cover, Bédéthèque link, and review status (use --favorites for _data/comics_favorites.yml)
ruby tools/manage-comic-covers.rb --status --year 2026
ruby tools/manage-comic-covers.rb --status --favorites

# Save cover copied to macOS clipboard (e.g. right-click "Copy Image" in browser)
ruby tools/manage-comic-covers.rb --clipboard <entry-id>

# Process scans/photos dropped into _covers_inbox/<entry-id>.{jpg,png,heic,webp}
ruby tools/manage-comic-covers.rb --inbox

# Set cover from a local image file or direct image URL
ruby tools/manage-comic-covers.rb --set <entry-id> /path/to/image-or-url

# Fetch high-confidence covers from open publisher og:image tags, Apple Books API, and Open Library
ruby tools/manage-comic-covers.rb --fetch-online --year 2026 --limit 20
```
