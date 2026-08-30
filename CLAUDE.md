# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

Personal research portfolio site of Junyoung Son (rgop13), served at https://rgop13.github.io via GitHub Pages. Work in this repo falls into two lanes:

- **Design**: designing and evolving the site's visual design. Always use the design skills for design/redesign work: `design-taste-frontend` and `frontend-design`.
- **Content**: concretizing, systematizing, and updating portfolio content — publications, projects, education, research interests.

Version control and deployment are git-based: committing and pushing to `main` is the deploy step — GitHub Pages builds the site from source automatically. Leave meaningful changes committed and pushed, not local-only.

## Commands

```bash
bundle install            # install the github-pages gem bundle
bundle exec jekyll serve  # local preview at http://localhost:4000, rebuilds on change
bundle exec jekyll build  # one-off build into _site/
```

No tests or linters. `Gemfile.lock` pins `github-pages` 209 (Jekyll 3.9.0, ~2020-era), so a modern Ruby may fail to bundle locally; the GitHub Pages deploy does not depend on a local build — pushing to `main` is sufficient. Verify visual changes with a local serve when possible.

## Architecture

Jekyll site using the "AP" (About/Portfolio) career theme by kssim (see README.md), vendored directly into the repo — there is no theme gem, so all layout and style changes are made to the files below.

- `index.md` — **essentially all portfolio content lives in this single file** (layout `about`), in this section order: About Me, Research Interest, Education, Publication (International Conference → International Journal → Domestic Conference → Domestic Journal → Preprint → Project).
- `_config.yml` — site/author metadata rendered by the layouts: name, affiliation, email, profile image (`assets/img/profile3.jpeg`), GitHub/LinkedIn handles for the social icons.
- Layout chain: `_layouts/base.html` (nav with About + Portfolio, footer) wraps `_layouts/about.html` (profile header + `index.md` content), `_layouts/portfolio.html` (paginated project cards), and `_layouts/post.html` (single portfolio entry).
- `_includes/head.html` (meta + stylesheet links) and `_includes/icons.html` (social icons driven by `_config.yml`).
- Styling: `assets/css/main.scss` (front-mattered entry point) imports `_sass/main.scss`, which imports `_sass/base/*` (incl. `_variables.scss` for colors/typography) and `_sass/layouts/*` (`_home.scss` styles the About page, `_portfolio.scss`, `_post.scss`, `_layout.scss`, `_footer.scss`). Font Awesome is vendored at `assets/css/fontawesome-all.min.css` + `assets/webfonts/`.

### Gotchas

- **Never edit `_site/`.** It is committed Jekyll build output (there is no `.gitignore`) and it is stale — it still contains 2017–2018 demo posts from the original theme. GitHub Pages regenerates everything from source and ignores `_site/`, so edits there are silently useless.
- The Portfolio nav page (`portfolio/index.html`) renders `paginator.posts`, but `paginate`/`paginate_path` are commented out in `_config.yml` and there is no `_posts/` directory — the page currently renders empty. Activating it requires both `_posts/` entries (with `title`/`type`/`info`/`tech` front matter used by `portfolio.html`) and re-enabling pagination.

## Content Conventions (index.md)

Publication entries follow a fixed pattern — keep it when adding or editing entries:

```markdown
* [Paper Title](https://link-to-paper) <br/>
<span style="color:rgb(73, 120, 173)"> Venue name, year </span> <br/>
Author One, **Junyoung Son**, Author Three (*: equal contributions)
<br/>
```

- Bold own name as `**Junyoung Son**`; mark equal contribution with `[\*]` after the name.
- Venue line uses the blue span `color:rgb(73, 120, 173)`.
- Newest entries first within each subsection; entries separated with `<br/>` lines.
- Project entries: bold title (Korean titles kept as-is) + `Participation Period: YYYY.MM ~ ...` line.
