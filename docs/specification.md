## Overview

This document specifies the configuration and template structure for a Hugo-based static blog using the **emtee** theme. Posts are stored as flat Markdown files named after their slug, with publish date stored in front matter. The home page displays the 20 most recent posts; older content is navigable via clean date-based archive URLs at `/YYYY/MM`, and individual posts resolve to `/YYYY/MM/DD/post-slug`.

All build logic — layouts, partials, stylesheets, archive-stub generation, and slug linting — lives inside the `themes/emtee/` directory. The site project contains only what is irreducibly site-specific: content, site configuration, and site-level static assets.

---

## Directory Structure

### Site Project (minimal)

```
my-blog/
+-- .hugo-version               # Pinned minimum Hugo version (e.g. 0.128.0)
+-- hugo.toml                   # Site-specific configuration (title, baseURL, author, etc.)
+-- content/
|   +-- posts/                  # ALL blog posts -- single flat directory
|   |   +-- _index.md           # Disables /posts/ section page (build settings only)
|   |   +-- hello-world.md
|   |   +-- my-second-post.md
|   |   +-- another-article.md
|   +-- 2024/                   # Generated archive stubs (theme script output)
|   |   +-- _index.md           # Year archive at /2024/
|   |   +-- 01/
|   |   |   +-- _index.md       # Month archive at /2024/01/
|   |   +-- 03/
|   |       +-- _index.md
|   +-- 2025/
|       +-- _index.md
|       +-- 11/
|           +-- _index.md
+-- static/
|   +-- favicon.ico
|   +-- og-default.png          # Fallback social-card image (1200x630)
|   +-- images/                 # Per-post media; mirrors post slugs one level deep
|       +-- hello-world/
|       |   +-- diagram.png
|       +-- deploying-with-github-actions/
|           +-- screenshot.png
+-- themes/
    +-- emtee/                  # The theme -- see below
```

The site project has no `layouts/`, `archetypes/`, or `assets/` directories. All of those live in the theme. Hugo's lookup order means the site project can override any individual theme file by placing a file at the equivalent path under the site root — but the default is to rely entirely on the theme.

### Theme (`themes/emtee/`)

```
themes/emtee/
+-- theme.toml                  # Theme metadata (name, minimum Hugo version)
+-- archetypes/
|   +-- default.md              # Post archetype: run `hugo new posts/my-post.md`
+-- scripts/
|   +-- gen-archives.sh         # Regenerates content/<YYYY>/_index.md stubs from posts
|   +-- lint-slugs.sh           # Enforces the post filename slug convention
+-- assets/
|   +-- css/
|       +-- main.scss           # Stylesheet entry point (processed by Hugo Pipes via css.Sass)
|       +-- components/
|           +-- _layout.scss    # CSS Grid layout
|           +-- _header.scss    # Site header styles
|           +-- _footer.scss    # Site footer styles
+-- layouts/
|   +-- _default/
|   |   +-- baseof.html         # Base template (wraps every page)
|   +-- home.html               # Home page template
|   +-- page.html               # Individual post template
|   +-- section.html            # Section / archive list template
|   +-- taxonomy.html           # Taxonomy index (e.g. /tags/)
|   +-- term.html               # Term page (e.g. /tags/general/)
|   +-- 404.html                # Not-found page
|   +-- robots.txt              # robots.txt template
|   +-- _partials/
|       +-- head.html           # <head> contents
|       +-- header.html         # Site header
|       +-- sidebar.html        # Sidebar (recent posts, tags, RSS)
|       +-- footer.html         # Site footer
|       +-- post-summary.html   # Post preview card (used by home.html)
|       +-- terms.html          # Taxonomy term list helper
+-- docs/
    +-- specification.md        # This document
    +-- phases.md               # Implementation phases
```

> **Note on `_partials/`:** Hugo ≥ 0.146 resolves partials from `layouts/_partials/` in addition to the traditional `layouts/partials/`. The theme targets Hugo ≥ 0.146 for this reason. If you need to support older Hugo, move all files from `_partials/` to `partials/`.

---

## Hugo Version

The blog targets **Hugo `>= 0.146.0`** to support `layouts/_partials/` resolution. The exact pinned version is recorded in `.hugo-version` at the repo root.

`.hugo-version`:

```
0.146.0
```

---

## Hugo Configuration (`hugo.toml`)

The site config lives at the project root as `hugo.toml`. It contains only values that differ per deployment; everything else is handled by the theme or Hugo defaults.

```toml
baseURL = "https://example.com/"
locale  = "en-us"
title = "My Blog"
theme = "emtee"

# Render robots.txt from the theme's layouts/robots.txt rather than Hugo's default.
enableRobotsTXT = true

# Use the `date` field in each post's front matter as the source of truth.
# `lastmod` is intentionally tied to `date` rather than `:fileModTime` so that
# touching a file does not silently change archive ordering or sitemap entries.
[frontmatter]
date        = ["date", ":fileModTime", ":default"]
publishDate = ["publishDate", "date", ":fileModTime", ":default"]
lastmod     = ["lastmod", "date"]

# Route all posts under /posts to /YYYY/MM/DD/slug
[permalinks]
posts = "/:year/:month/:day/:slug/"

# Home page shows 20 posts; archive pages use standard pagination.
# Requires Hugo >= 0.128 (replaces the deprecated `paginate` / `paginatePath` keys).
[pagination]
pagerSize = 20
path      = "page"

[params]
description   = "A personal blog"
mainSections  = ["posts"]

# Single-author site identity. Surfaced in footer, OG/Twitter meta, and copyright line.
author        = "Author Name"
authorBio     = "Short one-paragraph bio. Replace before launch."
ogImage       = "/og-default.png"   # 1200x630 fallback social card; per-post `image:` overrides this
twitterHandle = ""                  # Optional, e.g. "@example"; leave empty to omit twitter:site

[markup.goldmark.renderer]
unsafe = false

# RSS feed: cap each feed at the 20 most recent items.
[services.rss]
limit = 20

# [deployment] — site-specific; configure in the site project's hugo.toml.
# See docs/architecture.md for the recommended S3 + CloudFront setup.
```

### Key Configuration Decisions

| Setting | Value | Rationale |
|---|---|---|
| `theme` | `"emtee"` | All layouts, assets, scripts, and archetypes load from `themes/emtee/` |
| `[frontmatter] date` | `["date", ":fileModTime", ":default"]` | Hugo reads `date` from front matter; filename becomes the slug |
| `[permalinks] posts` | `/:year/:month/:day/:slug/` | Produces clean `/2024/01/15/hello-world/` URLs |
| `[pagination] pagerSize` | `20` | Posts per page on home and list pages |
| `[pagination] path` | `"page"` | Produces `/page/2/`, `/page/3/` for pagination continuations |

---

## Content: Post Markdown Files

### Filename Convention

Every post file is named after its URL slug — no date prefix:

```
post-slug.md
```

Examples:

```
content/posts/hello-world.md
content/posts/my-second-post.md
content/posts/deploying-with-github-actions.md
```

The slug is derived from the filename (without extension). The publish date is **not** encoded in the filename — it is stored in the post's front matter `date` field.

**Slug rules:**
- Lowercase ASCII letters (`a`-`z`), digits (`0`-`9`), and hyphens only.
- Hyphens separate words. No underscores, spaces, dots, or other punctuation.
- No leading or trailing hyphens; no consecutive hyphens.
- No file extensions other than `.md`.
- Recommended length ≤ 60 characters.
- Non-ASCII titles must be transliterated by hand to ASCII.

A regex that matches a valid slug filename: `^[a-z0-9]+(-[a-z0-9]+)*\.md$`.

The rules are enforced by `themes/emtee/scripts/lint-slugs.sh`, which runs before every Hugo build.

### Post Front Matter

```toml
+++
title = 'Hello World'
date = 2024-01-15T09:30:00-05:00
description = 'A short description for SEO and post summaries.'
tags = ['general', 'introduction']
draft = false
# slug = 'hello-world'                    # defaults to filename without extension
# image = '/images/hello-world/og.png'   # social-card override
+++

Post body content starts here.
```

**Required fields:** `title`, `date`
**Optional fields:** `description`, `tags`, `draft`, `slug`, `aliases`, `image`

### Disabling the `/posts/` Section Page (`content/posts/_index.md`)

```toml
+++
[build]
render = 'never'
list = 'never'
+++
```

### Archetype (`themes/emtee/archetypes/default.md`)

New posts created with `hugo new posts/my-post.md` use the theme's archetype:

```toml
+++
title = '{{ replace .File.ContentBaseName "-" " " | title }}'
date = '{{ .Date }}'
description = ''
tags = []
draft = true
# slug = ''
# image = ''
+++
```

To override the archetype for a specific site, place `archetypes/default.md` in the site root. Hugo's lookup order gives the site-level file priority.

---

## URL Structure

### Individual Posts

| File | Front matter `date` | Published URL |
|---|---|---|
| `hello-world.md` | `2024-01-15` | `/2024/01/15/hello-world/` |
| `deploying-with-github-actions.md` | `2025-11-20` | `/2025/11/20/deploying-with-github-actions/` |

### Home Page

`/` — Displays the 20 most recent posts. Older posts at `/page/2/`, `/page/3/`, etc.

### Monthly Archive Pages

Archive pages at `/YYYY/` and `/YYYY/MM/` are produced by `_index.md` stubs in a parallel `content/<YYYY>/<MM>/` tree. The stubs are generated by `themes/emtee/scripts/gen-archives.sh` and filtered by `section.html` using the `year`/`month` front matter values.

---

## Archive Pages: `/YYYY/MM/` Clean URLs

### Generated Stub Layout

```
content/
+-- posts/
|   +-- hello-world.md
+-- 2024/
|   +-- _index.md                   # /2024/
|   +-- 01/
|       +-- _index.md               # /2024/01/
+-- 2025/
    +-- _index.md
    +-- 11/
        +-- _index.md
```

### Stub Front Matter

Year stub (`content/2024/_index.md`):

```yaml
---
title: "2024"
year:  2024
---
```

Month stub (`content/2024/01/_index.md`):

```yaml
---
title: "January 2024"
year:  2024
month: 1
---
```

### Stub Generation Script (`themes/emtee/scripts/gen-archives.sh`)

Runs on every build and as a pre-commit hook. It:

1. Reads the `date` field from every `content/posts/*.md` file.
2. Computes the set of unique `(year)` and `(year, month)` pairs.
3. Writes `content/<YYYY>/_index.md` and `content/<YYYY>/<MM>/_index.md` stubs.
4. Removes stub directories for `(year, month)` pairs with no matching posts.

The stub files are committed to the repo so builds without the script still produce correct archive pages.

---

## Semantic HTML & Accessibility

The theme targets **WCAG 2.1 Level AA** compliance. Every template decision has both a semantic-correctness rationale and an accessibility rationale; they are inseparable.

### Semantic Element Usage

| Context | Element | Rationale |
|---|---|---|
| Site-wide banner | `<header>` as direct `<body>` child | Implicit `role="banner"` landmark |
| Primary content | `<main id="main-content">` | Implicit `role="main"` landmark; skip-link target |
| Sidebar navigation | `<aside>` with `aria-label` | Implicit `role="complementary"` landmark |
| Site-wide footer | `<footer>` as direct `<body>` child | Implicit `role="contentinfo"` landmark |
| Navigation menus | `<nav>` with unique `aria-label` | Implicit `role="navigation"`; label distinguishes multiple navs |
| Individual post | `<article>` | Self-contained content unit |
| Post list entry | `<article>` | Each summary is independently meaningful |
| Month group | `<section>` with visible `<h2>` | Groups related content; heading labels the section |
| Date/time values | `<time datetime="YYYY-MM-DD">` | Machine-readable date alongside human-readable display |
| Post tags | `<ul>` with `aria-label="Tags"` | List conveys multiplicity; label identifies purpose |

Use `<div>` and `<span>` only for styling hooks where no semantic element fits. Never use them as layout wrappers when block-level semantics are available.

### Heading Hierarchy

Every page has exactly one `<h1>` (the post title or page title). Section headings follow in order without skipping levels:

- `<h1>` — page title (inside `<main>`)
- `<h2>` — major sections within the page, or month groupings in archive lists
- `<h3>` — subsections within a major section

Sidebar headings (`<h2 class="sidebar-heading">`) are `<h2>` because `<aside>` is a sectioning element that resets the heading outline within it.

### Skip Navigation

Every page begins with a visually-hidden skip link as the first focusable element in `<body>`. It becomes visible on focus. Keyboard users and screen-reader users can bypass the repeated site header and reach the primary content directly.

```html
<a class="skip-link" href="#main-content">Skip to main content</a>
```

The target is `<main id="main-content">`. The skip link is styled in `main.css`:

```css
.skip-link {
  position: absolute;
  top: -100%;
  left: 0;
}
.skip-link:focus {
  top: 0;
}
```

### ARIA Landmarks

Landmark roles are provided implicitly by semantic elements — no explicit `role` attributes are needed. Every page has exactly these landmarks (in DOM order):

1. `<header>` — banner
2. `<main id="main-content">` — main
3. `<aside aria-label="…">` — complementary (label distinguishes it from main)
4. `<footer>` — contentinfo

Navigation elements within landmarks carry unique `aria-label` values to distinguish them when a user lists all nav landmarks:

- Site header nav: `aria-label="Main navigation"` (when present)
- Sidebar nav: `aria-label="Site navigation"`
- Pagination nav: `aria-label="Pagination"`
- Post-to-post nav: `aria-label="Post navigation"`

### Focus Management

- All interactive elements must be reachable and operable by keyboard alone.
- Focus order follows DOM order (ensured by putting `<main>` before `<aside>` in markup).
- Focus indicators must be clearly visible: `:focus-visible` styles override browser defaults where they are too subtle.
- Do not suppress focus outlines with `outline: none` without a visible replacement.

### Color & Contrast

- Normal text (`--fg` on `--bg`): minimum **4.5:1** contrast ratio (WCAG AA).
- Large text (≥ 18pt / 14pt bold) and UI components: minimum **3:1**.
- Link color (`--link` on `--bg`): minimum 4.5:1 against the background, and must differ from surrounding text by at least 3:1 if not underlined.
- Dark mode palette must independently satisfy the same ratios.

Tokens to verify:

| Pair | Light | Dark |
|---|---|---|
| `--fg` / `--bg` | #1a1a1a / #ffffff → 16.1:1 ✓ | #ececec / #0e0e10 → 14.7:1 ✓ |
| `--link` / `--bg` | #0050ff / #ffffff → 5.9:1 ✓ | #7aa7ff / #0e0e10 → 5.4:1 ✓ |
| `--fg-muted` / `--bg` | #555555 / #ffffff → 7.4:1 ✓ | #a0a0a0 / #0e0e10 → 6.4:1 ✓ |

### Link Text

All links must be descriptive without surrounding context:

- **Good:** `<a href="…">Read more about {{ .Title }}</a>`
- **Bad:** `<a href="…">Read more</a>` (ambiguous when listed by a screen reader)
- **Bad:** `<a href="…">Click here</a>`

"RSS feed" and "Skip to main content" are acceptable because they are self-describing.

### Image Alt Text

All `<img>` elements require an `alt` attribute. Decorative images use `alt=""`. Content images use a description of what the image conveys, not a description of the image file.

### Motion

Transitions and animations must respect `prefers-reduced-motion: reduce`. Wrap any CSS transition or animation in a media query:

```css
@media (prefers-reduced-motion: no-preference) {
  .skip-link { transition: top 0.1s; }
}
```

---

## Templates

All templates live in `themes/emtee/layouts/`. To override any template for a specific site, place the file at the equivalent path under the site root.

### Base Template (`themes/emtee/layouts/_default/baseof.html`)

```html
<!DOCTYPE html>
<html lang="{{ site.Language.Locale }}" dir="{{ or site.Language.Direction `ltr` }}">
<head>
  {{ partial "head.html" . }}
</head>
<body>
  <a class="skip-link" href="#main-content">Skip to main content</a>
  {{ partial "header.html" . }}
  <main id="main-content">
    {{ block "main" . }}{{ end }}
  </main>
  {{ partial "sidebar.html" . }}
  {{ partial "footer.html" . }}
</body>
</html>
```

`<header>`, `<main>`, `<aside>`, and `<footer>` are direct `<body>` children and CSS Grid items. `<main>` appears before `<aside>` in markup so screen readers encounter content before navigation. The skip link is the first focusable element on every page.

### Home Page (`themes/emtee/layouts/home.html`)

```html
{{ define "main" }}
<section class="post-list">
  <h1>Recent Posts</h1>

  {{ $paginator := .Paginate (where site.RegularPages "Section" "posts") }}

  {{ range $paginator.Pages }}
    {{ partial "post-summary.html" . }}
  {{ end }}

  {{ if gt $paginator.TotalPages 1 }}
  <nav class="pagination" aria-label="Pagination">
    {{ if $paginator.HasPrev }}
      <a href="{{ $paginator.Prev.URL }}">&larr; Newer Posts</a>
    {{ end }}
    {{ if $paginator.HasNext }}
      <a href="{{ $paginator.Next.URL }}">Older Posts &rarr;</a>
    {{ end }}
  </nav>
  {{ end }}
</section>
{{ end }}
```

### Individual Post (`themes/emtee/layouts/page.html`)

```html
{{ define "main" }}
<article class="post">
  <header>
    <h1>{{ .Title }}</h1>
    <time datetime="{{ .Date.Format "2006-01-02" }}">
      {{ .Date.Format "January 2, 2006" }}
    </time>
    {{ with .Params.tags }}
    <ul class="tags" aria-label="Tags">
      {{ range . }}<li><a href="{{ "/tags/" | relURL }}{{ . | urlize }}/">{{ . }}</a></li>{{ end }}
    </ul>
    {{ end }}
  </header>

  <div class="post-content">
    {{ .Content }}
  </div>

  <nav class="post-nav" aria-label="Post navigation">
    {{ with .PrevInSection }}
      <a href="{{ .Permalink }}" rel="prev">&larr; {{ .Title }}</a>
    {{ end }}
    {{ with .NextInSection }}
      <a href="{{ .Permalink }}" rel="next">{{ .Title }} &rarr;</a>
    {{ end }}
  </nav>
</article>
{{ end }}
```

### Archive / Section List (`themes/emtee/layouts/section.html`)

Used for `/YYYY/`, `/YYYY/MM/`, and any other section listing. When the section's `_index.md` carries `year` and/or `month` front matter (as generated by `gen-archives.sh`), the template filters `site.RegularPages` by those values. Otherwise it falls through to `.Pages` directly (e.g. for `/posts/` if that section is ever enabled).

`taxonomy.html` and `term.html` follow the same pattern for tag listing pages.

```html
{{ define "main" }}
<section class="archive">
  <h1>{{ .Title }}</h1>

  {{ $posts := .Pages }}
  {{ if or .Params.year .Params.month }}
    {{ $posts = where site.RegularPages "Section" "posts" }}
    {{ with .Params.year  }}{{ $posts = where $posts "Date.Year"  . }}{{ end }}
    {{ with .Params.month }}{{ $posts = where $posts "Date.Month" . }}{{ end }}
  {{ end }}

  {{ $paginator := .Paginate $posts }}

  {{ range $paginator.Pages.GroupByDate "January 2006" }}
  <section class="archive-month">
    <h2>{{ .Key }}</h2>
    <ul>
      {{ range .Pages }}
      <li>
        <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "Jan 02" }}</time>
        <a href="{{ .Permalink }}">{{ .Title }}</a>
      </li>
      {{ end }}
    </ul>
  </section>
  {{ end }}

  {{ if gt $paginator.TotalPages 1 }}
  <nav class="pagination" aria-label="Pagination">
    {{ if $paginator.HasPrev }}
      <a href="{{ $paginator.Prev.URL }}">&larr; Newer</a>
    {{ end }}
    {{ if $paginator.HasNext }}
      <a href="{{ $paginator.Next.URL }}">Older &rarr;</a>
    {{ end }}
  </nav>
  {{ end }}

</section>
{{ end }}
```

### Post Summary Partial (`themes/emtee/layouts/_partials/post-summary.html`)

```html
<article class="post-summary">
  <header>
    <h2><a href="{{ .Permalink }}">{{ .Title }}</a></h2>
    <time datetime="{{ .Date.Format "2006-01-02" }}">
      {{ .Date.Format "January 2, 2006" }}
    </time>
  </header>
  {{ with .Description }}
    <p class="description">{{ . }}</p>
  {{ else }}
    <p>{{ .Summary }}</p>
  {{ end }}
  <a class="read-more" href="{{ .Permalink }}" aria-label="Read more about {{ .Title }}">Read more &rarr;</a>
</article>
```

### Head Partial (`themes/emtee/layouts/_partials/head.html`)

```html
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{ if .IsHome }}{{ .Site.Title }}{{ else }}{{ .Title }} -- {{ .Site.Title }}{{ end }}</title>

{{ $description := cond .IsHome .Site.Params.description (or .Description .Summary) }}
<meta name="description" content="{{ $description }}">

<link rel="canonical" href="{{ .Permalink }}">

{{ $ogImage := absURL (or .Params.image .Site.Params.ogImage) }}
{{ $ogTitle := cond .IsHome .Site.Title .Title }}
<meta property="og:title"       content="{{ $ogTitle }}">
<meta property="og:description" content="{{ $description }}">
<meta property="og:url"         content="{{ .Permalink }}">
<meta property="og:site_name"   content="{{ .Site.Title }}">
<meta property="og:type"        content="{{ if .IsPage }}article{{ else }}website{{ end }}">
<meta property="og:image"       content="{{ $ogImage }}">
{{ if .IsPage -}}
<meta property="article:published_time" content="{{ .Date.Format "2006-01-02T15:04:05Z07:00" }}">
<meta property="article:author"         content="{{ .Site.Params.author }}">
{{- end }}

<meta name="twitter:card"        content="summary_large_image">
<meta name="twitter:title"       content="{{ $ogTitle }}">
<meta name="twitter:description" content="{{ $description }}">
<meta name="twitter:image"       content="{{ $ogImage }}">
{{ with .Site.Params.twitterHandle -}}
<meta name="twitter:site" content="{{ . }}">
{{- end }}

{{ $css := resources.Get "css/main.scss" | css.Sass | resources.Minify | resources.Fingerprint }}
<link rel="stylesheet" href="{{ $css.RelPermalink }}">

{{ range .AlternativeOutputFormats -}}
  {{ printf `<link rel=%q type=%q href=%q title=%q>` .Rel .MediaType.Type .Permalink $.Site.Title | safeHTML }}
{{ end }}
```

`resources.Get "css/main.scss"` resolves to `themes/emtee/assets/css/main.scss` via Hugo's asset lookup order. `css.Sass` is provided by Hugo extended (embedded Dart Sass — no external tooling required) and resolves all `@import` statements at build time. The description chain (front-matter `description` → auto `.Summary` → `site.Params.description`) ensures every page has a non-empty description.

### Header Partial (`themes/emtee/layouts/_partials/header.html`)

```html
<header class="site-header">
  <a href="{{ "/" | relURL }}" class="site-title" rel="home">
    {{ .Site.Title }}
  </a>
</header>
```

### Sidebar Partial (`themes/emtee/layouts/_partials/sidebar.html`)

```html
<aside class="sidebar" aria-label="Site navigation">
  <nav class="sidebar-nav">
    <h2 class="sidebar-heading">Subscribe</h2>
    <ul>
      <li>
        <a href="{{ "/index.xml" | absURL }}"
           rel="alternate"
           type="application/rss+xml">
          RSS feed
        </a>
      </li>
    </ul>
    <h2 class="sidebar-heading">Recent Posts</h2>
    <ul>
      {{ range first 5 (where site.RegularPages "Section" "posts") }}
        <li><a href="{{ .RelPermalink }}">{{ .LinkTitle }}</a></li>
      {{ end }}
    </ul>
    {{ with site.Taxonomies.tags }}
    <h2 class="sidebar-heading">Tags</h2>
    <ul>
      {{ range $name, $pages := . }}
        <li><a href="{{ (site.GetPage (printf "/tags/%s" $name)).RelPermalink }}">{{ $name }}</a></li>
      {{ end }}
    </ul>
    {{ end }}
  </nav>
</aside>
```

### Footer Partial (`themes/emtee/layouts/_partials/footer.html`)

```html
<footer class="site-footer">
  <p class="bio">
    <strong>{{ .Site.Params.author }}</strong>
    -- {{ .Site.Params.authorBio }}
  </p>
  <p class="copyright">
    &copy; {{ now.Format "2006" }} {{ .Site.Params.author }}. All rights reserved.
  </p>
</footer>
```

### 404 Page (`themes/emtee/layouts/404.html`)

```html
{{ define "main" }}
<section class="not-found">
  <h1>Page not found</h1>
  <p>The page you were looking for doesn't exist or has moved.</p>
  <p><a href="{{ "/" | relURL }}">Return to the home page</a>.</p>

  <h2>Recent posts</h2>
  <ul>
    {{ range first 5 (where site.RegularPages "Section" "posts") }}
    <li>
      <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "Jan 2, 2006" }}</time>
      <a href="{{ .Permalink }}">{{ .Title }}</a>
    </li>
    {{ end }}
  </ul>
</section>
{{ end }}
```

### robots.txt (`themes/emtee/layouts/robots.txt`)

```
User-agent: *
Allow: /

Sitemap: {{ "sitemap.xml" | absURL }}
```

### RSS

Hugo's built-in RSS output is used as-is. Feed item content is full post bodies (Hugo default). The item cap is controlled by `[services.rss] limit = 20` in `hugo.toml` — no custom template required.

---

## Styling

The stylesheet entry point is `themes/emtee/assets/css/main.scss`. It uses SCSS `@import` to pull in component partials, then declares base rules (custom properties, dark mode, body, typography, skip link, focus styles). Component files use only plain CSS — no Sass-specific syntax. SCSS is used solely for its `@import` resolution at build time.

Hugo extended includes embedded Dart Sass, so no external tooling is required.

### File Structure

```
assets/css/
+-- main.scss              # Entry point: @imports components, declares base rules
+-- components/
    +-- _layout.scss       # CSS Grid container and column rules
    +-- _header.scss       # .site-header, .site-title
    +-- _footer.scss       # .site-footer
    +-- _sidebar.scss      # .sidebar, .sidebar-nav, .sidebar-heading
    +-- _post.scss         # .post, .post-content, .post-nav, .tags
    +-- _post-summary.scss # .post-summary, .read-more, .post-list
    +-- _archive.scss      # .archive, .archive-month, .pagination, .taxonomy-list
```

Underscore-prefixed files are SCSS partials — they are not compiled independently, only via `@import` from `main.scss`.

### Asset Pipeline

The stylesheet flows through Hugo Pipes in `_partials/head.html`:

1. **`resources.Get "css/main.scss"`** — pulls from `themes/emtee/assets/css/`.
2. **`css.Sass`** — compiles SCSS and resolves all `@import` statements into a single file.
3. **`resources.Minify`** — strips whitespace and comments for production.
4. **`resources.Fingerprint`** — appends a content hash to the filename for cache-busting and SRI.

### Color Tokens & Dark Mode

Color tokens are declared as CSS custom properties on `:root`, with a `prefers-color-scheme: dark` override. The browser picks the active palette; there is no manual toggle.

```css
:root {
  --bg:        #ffffff;
  --fg:        #1a1a1a;
  --fg-muted:  #555555;
  --link:      #0050ff;
  --border:    #e5e5e5;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg:        #0e0e10;
    --fg:        #ececec;
    --fg-muted:  #a0a0a0;
    --link:      #7aa7ff;
    --border:    #2a2a2a;
  }
}

body {
  background: var(--bg);
  color: var(--fg);
}
```

Components use only the `--*` tokens, never raw colors.

### Accessibility Styles (`main.css`)

These rules are declared in `main.css` alongside the base rules, not in a component file, because they apply globally.

```css
/* Skip link — visually hidden until focused */
.skip-link {
  position: absolute;
  top: -100%;
  left: 0;
  padding: 0.5rem 1rem;
  background: var(--bg);
  color: var(--link);
  z-index: 100;
}
.skip-link:focus {
  top: 0;
}

/* Focus indicator — visible on keyboard navigation, suppressed on pointer click */
:focus-visible {
  outline: 2px solid var(--link);
  outline-offset: 2px;
}
:focus:not(:focus-visible) {
  outline: none;
}

/* Motion — wrap any transitions or animations here */
@media (prefers-reduced-motion: no-preference) {
  .skip-link {
    transition: top 0.1s;
  }
}
```

### Layout Grid (`components/layout.css`)

Two-column desktop layout with single-column mobile fallback:

```css
body {
    display: grid;
    grid-template-columns: 25rem 25rem;
    column-gap: 0.75rem;
    max-width: 50.75rem;
    margin: 0 auto;
}

header, footer { grid-column: 1 / -1; }
main            { grid-column: 1; }
aside           { grid-column: 2; }

@media (max-width: 48rem) {
    body { grid-template-columns: 1fr; }
    main, aside { grid-column: 1; }
}
```

---

## Post Media

Per-post images live under `static/images/<post-slug>/` in the **site project**. Reference them with root-relative paths:

```markdown
![A diagram](/images/hello-world/diagram.png)
```

---

## Behavior Summary

| URL | Content | Template |
|---|---|---|
| `/` | 20 most recent posts | `layouts/home.html` |
| `/page/2/` | Posts 21–40 | `layouts/home.html` (paginator page 2) |
| `/2024/01/` | January 2024 posts (first 20) | `layouts/section.html` |
| `/2024/` | All 2024 posts (first 20) | `layouts/section.html` |
| `/2024/01/15/hello-world/` | Individual post | `layouts/page.html` |
| `/tags/general/` | Posts tagged "general" | `layouts/term.html` |
| `/tags/` | All tags | `layouts/taxonomy.html` |
| `/robots.txt` | Allow-all + sitemap | `layouts/robots.txt` |
| `/sitemap.xml` | Auto-generated sitemap | Hugo built-in |
| unmatched URL | "Page not found" + 5 recent posts | `layouts/404.html` |

---

## Caveats and Known Limitations

1. **`/YYYY/MM/` pages depend on the stub generator.** Always run `gen-archives.sh` before `hugo build`.

2. **Duplicate slug collisions.** Two posts with the same slug collide on disk. Use `hugo --printPathWarnings` to detect URL-level collisions.

3. **Front matter `date` is required.** Without it Hugo falls back to file modification time, which silently corrupts archive ordering.

4. **`.Paginate` is called once per template invocation.** `home.html` and `section.html` each call it exactly once.

5. **Hugo version ≥ 0.146 required.** The `_partials/` directory convention is not supported in older Hugo. Downgrading requires renaming `_partials/` to `partials/`.

6. **Overriding theme files.** Place a file at the equivalent path under the site root to override any theme layout or partial. Use sparingly — drifting from the theme makes upgrades harder.
