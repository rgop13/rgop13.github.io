# Portfolio Redesign Design Spec: "Well-typeset Paper"

- **Site**: https://rgop13.github.io (Jekyll + GitHub Pages)
- **Date**: 2026-08-30
- **Status**: Approved direction (editorial academic, KU crimson accent, one-page anchor nav). This document is the implementation source of truth.

## 한국어 요약

- **컨셉**: "잘 조판된 논문 한 편" 같은 정제된 에디토리얼 아카데믹 원페이지. 콘텐츠(논문·프로젝트·학력)는 전부 보존, 비주얼 언어는 전면 교체.
- **컬러**: 차가운 오프화이트 종이(`#FCFCFA`) + 잉크(`#1B1B1F`) + **KU 크림슨 액센트(`#8E2438`) 단 하나**. 기존 마크다운의 파란 인라인 span 전부 제거.
- **타이포**: 과학출판 컨소시엄 서체 **STIX Two Text**(제목·본문) + **IBM Plex Sans**(UI·한글 포함 라벨) + **IBM Plex Mono**(연도·venue 약칭 메타데이터). woff2 셀프호스팅.
- **시그니처**: Selected Publications의 **venue 약칭 대형 모노 배지**(COLING, EMNLP...). 1저자·Oral은 크림슨 태그.
- **구조**: 나브는 About · Publications · Projects 앵커. 빈 /portfolio 페이지와 죽은 테마 코드는 삭제. 논문·프로젝트는 `_data/*.yml`로 데이터화해서 이후 업데이트는 YAML 한 항목 추가로 끝나게 함.
- **모션**: 히어로 라인 순차 페이드인 + 섹션 진입 리빌 + 호버 크림슨 전환만. `prefers-reduced-motion` 존중.

---

## 1. Goal & Scope

Replace the default-looking AP theme visuals with a distinctive, credible editorial-academic design, and systematize the content so future updates are data edits, not markdown surgery.

In scope: full visual rewrite (SCSS, layouts, includes, head), content restructuring into data files, dead-code cleanup, accessibility fixes, light motion layer.
Out of scope: dark mode (deliberate print-editorial light-only lock), blog/detail pages, content rewriting beyond formatting, analytics changes.

## 2. Design Read & Dials

Reading this as: **researcher portfolio (NLP PhD student: retrieval + information extraction) for professors, recruiters, and academic peers, with a refined editorial-academic language, built on hand-written modern CSS inside Jekyll (no JS framework).**

Dials: `DESIGN_VARIANCE: 5`, `MOTION_INTENSITY: 3`, `VISUAL_DENSITY: 3`.

Anti-default commitments: no warm-cream AI palette, no trend serif (Fraunces/Instrument), no centered hero, no purple, zero em-dashes in page copy, boldness spent on exactly one signature element.

## 3. Design Tokens

### 3.1 Color (single light theme)

| Token | Value | Usage |
|---|---|---|
| `--paper` | `#FCFCFA` | page background |
| `--ink` | `#1B1B1F` | headings, body text |
| `--ink-soft` | `#50505A` | secondary text: author lines, dates, captions |
| `--hairline` | `#E4E4E0` | rules, borders, dividers |
| `--accent` | `#8E2438` | KU crimson: links, hovers, highlight tags, name marker |
| `--accent-deep` | `#711C2D` | accent hover/active state |

Rules: exactly one accent, used identically everywhere (Color Consistency Lock). Contrast: ink on paper ≈ 15:1, accent on paper ≈ 8.3:1 (AAA). No pure `#000`/`#fff`. The legacy `rgb(73,120,173)` venue spans and `midnightblue` are removed with the content migration.

### 3.2 Typography

| Role | Face | Fallbacks |
|---|---|---|
| Display + body serif | **STIX Two Text** (400/400i/600/700) | Times New Roman, serif |
| UI sans (nav, labels, author lines, Korean text) | **IBM Plex Sans** (400/500/600) | Apple SD Gothic Neo, Malgun Gothic, Helvetica Neue, sans-serif |
| Metadata mono (years, venue acronyms, periods, tags) | **IBM Plex Mono** (400/600) | Menlo, monospace |

Rationale: STIX Two was commissioned by the scientific-publishing consortium (Elsevier, IEEE, AMS et al.); "the typeface of papers" as display type is the subject-grounded choice for a researcher. Plex Sans/Mono carry the technical register.

Self-host woff2 (latin subsets) under `assets/webfonts/` with `@font-face` + `font-display: swap`; remove the Google Fonts `<link>`. **Hangul strategy**: Korean strings (project titles, HCLT titles) are always set in the sans stack, falling back to system Korean fonts (Apple SD Gothic Neo / Malgun Gothic). No Korean webfont payload; serif is never applied to Hangul.

### 3.3 Type scale

| Element | Spec |
|---|---|
| Hero name | serif 600, `clamp(2.75rem, 6vw, 4.25rem)`, line-height 1.05, letter-spacing -0.01em |
| Hero statement | serif 400, 1.25rem, line-height 1.55, max 2 sentences |
| Section heading | serif 600, 1.6rem, with a full-width hairline rule below |
| Publication title | serif 600, 1.125rem, line-height 1.4 |
| Author line / body meta | sans 400, 0.9rem, `--ink-soft`; own name = sans 600 `--ink` |
| Venue badge (selected) | mono 600, 1.3rem, uppercase |
| Venue/year meta (list) | mono 400, 0.8rem, uppercase, letter-spacing 0.06em |
| Tags (oral, award) | mono 600, 0.7rem, uppercase, crimson text + 1px crimson border |

Base font-size 17px, body measure ≤ 70ch. Line-height: 1.55 body, `normal` overrides from the old theme are removed.

### 3.4 Spacing, shape, layout constants

- Container: `max-width: 880px`, `padding-inline: clamp(1.25rem, 5vw, 2.5rem)`.
- Section padding-block: `clamp(4rem, 9vh, 6.5rem)` (density 3, gallery-side).
- Shape lock: single radius token `--radius: 2px` (images, tags). Everything else square. No shadows except the existing-nav shadow which is removed; elevation is expressed with hairlines only.
- Photo: 4:5 portrait, ~200px wide on desktop, 1px hairline border, `--radius`.

## 4. Page Architecture

One page (`/`), anchor navigation. `/portfolio` and its machinery are deleted (approved IA change).

```
nav      Junyoung Son                About · Publications · Projects
hero     [left] name / 1-2 sentence research statement /
         affiliation + advisor line / link row (Scholar·GitHub·LinkedIn·Email)
         [right] portrait photo
#about   short prose (from index.md) + research interest terms + education (compact)
#publications
         Selected Publications  (signature treatment, 4-6 entries)
         All Publications       (grouped: Intl. Conference / Intl. Journal /
                                 Domestic / Preprint; compact rows)
#projects  2-column grid of project cards (title, period, one-line role if present)
footer   contact line + copyright (theme credit removed; LICENSE file stays)
```

### 4.1 Nav

Sticky, `--paper` background, bottom hairline (no box-shadow). Left: name in serif 600. Right: three anchor links in sans, single line, height ≤ 64px. Active-section state: crimson text (IntersectionObserver; graceful without JS). Mobile: name + links share one row if they fit at 390px (they do at 0.85rem); no hamburger.

### 4.2 Hero (asymmetric split, left-aligned)

Grid `1fr auto`; text block left, photo right. Max 4 text elements: name, statement, affiliation line, link row. Statement is plain serif with the two research-area terms (`retrieval`, `information extraction`) in serif italic, same family (emphasis rule: same-family italic, never a second family). Link row: sans small-caps-free plain labels separated by middle dots (max usage: this one row). Mobile < 768px: photo stacks above name at 120px wide.

### 4.3 Selected Publications (signature)

Grid rows `[7.5rem badge] [1fr content] [auto year]`:

- Badge column: large mono venue acronym (`COLING`, `EMNLP`, `ACL`, `IEEE Access`) top-aligned; tags (`ORAL`, `1ST AUTHOR` where true) stacked under it in crimson outline chips.
- Content: serif title (link, ink; hover: crimson), sans author line with own name emphasized and `*` for equal contribution.
- Year right-aligned mono.
- Row separation: single bottom hairline per row (never top+bottom).
- Hover: title color transitions to crimson; no transforms.

Initial `selected: true` set (adjustable by user in YAML): GRASP (COLING 2022, oral), Explore the Way (EMNLP 2023 Findings), Post-hoc Utterance Refining (EMNLP 2023), From Ambiguity to Accuracy (ACL 2025 SRW), AI for Patents (IEEE Access 2022), KURE (HCLT 2025).

### 4.4 All Publications

Grouped under mono group labels (International Conference, International Journal, Domestic Conference & Journal, Preprint). Compact two-line rows: title (serif, link) + one meta line `mono venue-short · year` followed by sans author line. No badges here; the selected section keeps the spotlight. Entries newest-first within groups (current convention preserved).

### 4.5 Projects

2-column grid (≥768px), 1-column below. Card = hairline-bordered block (`--radius`): Korean title in sans 600 (Hangul rule), period in mono, optional one-line role. No images (none exist; no fake visuals).

### 4.6 About / Education

About prose stays markdown-authored (index.md). Research interests as an inline term row (sans, separated by hairline-bordered chips), not a bullet list. Education as two compact rows (degree, institution, period in mono).

## 5. Motion (intensity 3)

1. Page load: hero children fade/translate-in, staggered 60ms, 500ms, `cubic-bezier(0.16,1,0.3,1)`. Pure CSS (`animation-delay` cascade).
2. Scroll reveal: publication rows and project cards `opacity 0→1, translateY 12px→0` via one small IntersectionObserver script (`assets/js/reveal.js`, ~30 lines, no dependencies). Content is visible without JS (reveal class only added when JS runs).
3. Hover: link/title color transitions (200ms), underline on body links (crimson, 2px offset).

All of 1-2 wrapped in `@media (prefers-reduced-motion: no-preference)`. Nothing loops. Only `transform`/`opacity` animate.

## 6. Data Architecture

### `_data/publications.yml`

```yaml
- id: grasp-coling2022
  selected: true
  group: intl-conference    # intl-conference | intl-journal | domestic | preprint
  title: "GRASP: Guiding model with RelAtional Semantics using Prompt"
  url: https://aclanthology.org/2022.coling-1.33/
  venue: "The 29th International Conference on Computational Linguistics (COLING 2022)"
  venue_short: COLING
  year: 2022
  tags: [oral]              # optional: oral | award
  authors:
    - { name: Junyoung Son, me: true, equal: true }
    - { name: Jinsung Kim, equal: true }
    - { name: Jungwoo Lim, equal: true }
    - { name: Heuiseok Lim }
```

Author-line rendering (include): join names with commas, bold `me`, append `*` to `equal`, append `(*: equal contributions)` when any `equal` present. All 20 current entries are migrated verbatim from index.md (titles, links, venues, author order preserved exactly; the single domestic-journal entry folds into `domestic` alongside the 9 domestic-conference entries).

### `_data/projects.yml`

```yaml
- title: "KURE: Korea University Retrieval Embedding Model 개발"
  period: "2024.08 ~ 2024.12"
  role: ""                  # optional one-liner
```

Rendering via `_includes/publications.html`, `_includes/projects.html`, `_includes/hero.html`, `_includes/education.html`, composed by the rewritten home layout.

## 7. File-Level Change Map

| Path | Action |
|---|---|
| `_sass/**` | full rewrite: `_tokens.scss`, `_base.scss`, `_nav.scss`, `_hero.scss`, `_publications.scss`, `_projects.scss`, `_footer.scss`, `main.scss` |
| `_layouts/base.html` | rewrite: nav (anchors), footer (own copyright, no theme credit) |
| `_layouts/about.html` | replaced by `_layouts/home.html` composing section includes |
| `_layouts/portfolio.html`, `_layouts/post.html` | delete (dead) |
| `_includes/head.html` | rewrite: @font-face preloads, meta description, OG tags; drop Google Fonts link |
| `_includes/icons.html` | replaced by plain text links in hero (Font Awesome dependency dropped if unused elsewhere; `fontawesome-all.min.css` + `assets/webfonts/fa-*` removed) |
| `index.md` | slims to front matter + About prose + education data |
| `_data/publications.yml`, `_data/projects.yml` | new |
| `assets/webfonts/` | add STIX Two Text + Plex Sans + Plex Mono woff2 (latin) |
| `assets/js/reveal.js` | new (~30 lines) |
| `portfolio/index.html` | delete (approved: /portfolio 404s; page was empty) |
| `_config.yml` | remove paginate remnants + jekyll-paginate plugin; add `docs` to `exclude` |
| `.travis.yml` | delete (Travis CI defunct) |
| `_site/` | `git rm -r` from tracking + add to `.gitignore` (GitHub Pages rebuilds from source) |

## 8. Preservation Rules

- Content text of every publication/project/education entry preserved verbatim (migration is format-only).
- Root URL, site title, author metadata, profile photo asset, GitHub/LinkedIn/Scholar/email links preserved.
- LICENSE file stays (theme is MIT; footer credit removal is legal, license retention is required).
- CLAUDE.md conventions section will be updated after implementation to describe the YAML workflow (publications live in `_data/`, not index.md).

## 9. Accessibility & Performance

- All text AA minimum; body ink is ~15:1, links get underlines (not color-only affordance).
- Visible `:focus-visible` outlines (2px crimson offset 2px) on all interactive elements.
- Semantic landmarks: `<nav>`, `<main>`, `<section aria-labelledby>`, single `<h1>` (hero name).
- Fonts: woff2 subsets, `font-display: swap`, preload the two above-the-fold faces; total added font weight target < 220KB.
- No JS frameworks; one deferred script. Images: explicit width/height to avoid CLS.

## 10. Verification Plan

1. `bundle exec jekyll build` locally (ruby 2.6 + github-pages 209 lockfile; if local bundle fails, run build via `gem install jekyll -v 3.9.0` fallback and note it).
2. Screenshot pass with local Chromium (Playwright) at 1440 / 768 / 390 widths; visual review against this spec (typography, spacing, signature treatment).
3. Content diff check: every title/link/author string in `_data/*.yml` matched against the old index.md (scripted grep count: 6 intl-conference, 3 intl-journal, 10 domestic = 9 conference + 1 journal, 1 preprint, 8 projects).
4. Pre-flight checklist (adapted): zero em-dashes in page copy, one accent, one radius, nav single-line, no dead links, reduced-motion verified by emulation, focus states visible.
5. Push to `main` only after local build + screenshot review; verify live site after Pages build.

## 11. Out of Scope / Future

- Dark mode (revisit only if requested; current lock is deliberate).
- CV PDF link (the commented-out CV link in index.md stays commented until the user provides a current file).
- News/awards section, per-project pages, publication thumbnails.
