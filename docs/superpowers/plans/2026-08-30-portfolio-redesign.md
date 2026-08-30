# Portfolio Redesign ("Well-typeset Paper") Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild rgop13.github.io's visual layer as a one-page editorial-academic portfolio (KU crimson accent, STIX Two Text + IBM Plex, venue-badge signature) and migrate publications/projects into `_data/*.yml`.

**Architecture:** Jekyll 3.9 (github-pages 209) static site, hand-written SCSS with CSS custom-property tokens, Liquid includes rendering YAML data, one ~40-line vanilla JS file for scroll reveal + nav state. No frameworks. Deploy = push to `main` (GitHub Pages builds from source).

**Tech Stack:** Jekyll 3.9 / Liquid / SCSS / vanilla JS / self-hosted woff2 fonts / Playwright (Chromium) for screenshot verification / `python3 -m http.server` for local serving.

**Spec:** `docs/superpowers/specs/2026-08-30-portfolio-redesign-design.md` (read it first; this plan implements it 1:1).

## Global Constraints

- Color tokens, verbatim: `--paper:#FCFCFA` `--ink:#1B1B1F` `--ink-soft:#50505A` `--hairline:#E4E4E0` `--accent:#8E2438` `--accent-deep:#711C2D`. Exactly ONE accent; no other hues anywhere.
- Shape: single radius token `--radius: 2px`. No box-shadows. Elevation = hairlines only.
- Fonts: STIX Two Text (display+body serif), IBM Plex Sans (UI + all Korean text), IBM Plex Mono (metadata). Self-hosted woff2, `font-display: swap`. Korean text must NEVER get the serif stack.
- Zero em-dashes (`—`) and zero en-dash separators (`–`) in any template/design string. (User-content strings migrated verbatim are exempt but should be reviewed if the Task 7 scan hits.)
- Middle dot (`·`) max once per rendered line.
- Contrast: body AA minimum (tokens above give ~15:1 body, ~8.3:1 accent). Links must have a non-color affordance (underline) in prose.
- All animation: `transform`/`opacity` only, gated behind `prefers-reduced-motion: no-preference`; page fully readable with JS disabled.
- Content preservation: every publication/project/education string migrates verbatim from `index.md` as of commit `05a2a6d` (`git show 05a2a6d:index.md`). Formatting-only changes allowed; two flagged exceptions in Task 2.
- Base font 17px; container `max-width: 880px`; section padding-block `clamp(4rem, 9vh, 6.5rem)`.
- One theme (light). No dark-mode blocks.
- Screenshots go to `.omc/shots/` (git-ignored). Never commit screenshots or `_site/` changes.
- Every commit message ends with the standard co-author trailer used in this repo (see `git log -1 05a2a6d`).

---

### Task 1: Baseline build + screenshot tooling (no site changes)

**Files:**
- Modify: `.gitignore` (append build-tool dirs)
- Everything else: read-only; artifacts land in `.omc/shots/`

**Interfaces:**
- Produces: a working `jekyll build` invocation (call it `$JEKYLL_BUILD` below; later tasks reuse whichever variant succeeded) and a working screenshot loop (`serve → shoot → kill`).

- [ ] **Step 1: Try the bundled build (preferred)**

```bash
cd "/Users/junyoung/Documents/New project/rgop13.github.io"
bundle install --path vendor/bundle && bundle exec jekyll build --trace
```

Expected: `_site/` regenerated without error. If `bundle install` fails on native extensions (nokogiri/ffi/eventmachine are the likely culprits on this 2020-era lockfile), go to Step 2; otherwise skip to Step 3 with `$JEKYLL_BUILD = bundle exec jekyll build`.

- [ ] **Step 2 (fallback): Standalone Jekyll 3.9**

```bash
gem install --user-install jekyll -v 3.9.3 jekyll-paginate -v 1.1.0
export PATH="$(ruby -e 'print Gem.user_dir')/bin:$PATH"
jekyll build --trace
```

Expected: `_site/` regenerated. `$JEKYLL_BUILD = jekyll build` (with the PATH export). If BOTH steps fail: STOP, report the exact errors to the user with options (Homebrew ruby, Docker, or CI build). Do not proceed blind.

- [ ] **Step 3: Ignore build-tool dirs**

Append to `.gitignore`:

```
vendor/
.bundle/
```

- [ ] **Step 4: Verify screenshot tooling and take BEFORE shots**

```bash
mkdir -p .omc/shots
npx --yes playwright --version || npx --yes playwright install chromium
(cd _site && python3 -m http.server 4123 &) && sleep 1
npx playwright screenshot --viewport-size=1440,1000 --full-page http://localhost:4123/ .omc/shots/before-desktop.png
npx playwright screenshot --viewport-size=390,844  --full-page http://localhost:4123/ .omc/shots/before-mobile.png
pkill -f "http[.]server 4123"
```

Expected: two PNGs exist; view them (Read tool) to confirm the current bland site renders. This validates the whole verification loop before any change.

- [ ] **Step 5: Commit**

```bash
git add .gitignore && git commit -m "chore: ignore local bundler dirs"
```

---

### Task 2: Migrate content to `_data/publications.yml` + `_data/projects.yml`

**Files:**
- Create: `_data/publications.yml`, `_data/projects.yml`, `scripts/check_data.rb`
- Source of truth: `git show 05a2a6d:index.md` (do NOT edit index.md yet)

**Interfaces:**
- Produces: `site.data.publications` (list; fields `id, selected, group, title, url, venue, venue_short, venue_note?, year, tags?, authors[{name, me?, equal?}]`) and `site.data.projects` (list; fields `title, period`). Task 4's includes consume exactly these names.

**Two flagged content fixes (report both to the user at final review):**
1. The "Prompt Language Learner with Trigger Generation…" entry links to MDPI (`mdpi.com/2076-3417/13/22/12414` = Applied Sciences 13(22), 2023) but the old site labels it "IEEE Access, vol. 10, pp. 59205-59218, 2022" (copy-paste of the AI-for-Patents venue line). Migrate with the venue matching the actual link: `venue: "Applied Sciences, 13(22), 12414, 2023"`, `venue_short: "Appl. Sci."`, `year: 2023`.
2. The HCLT 2021 and HCLT 2022 entries both say "The 33rd Annual Conference"; preserved verbatim as-is (user's text, low stakes).

- [ ] **Step 1: Write `_data/publications.yml`**

Schema by example (three representative entries; follow these exactly):

```yaml
- id: grasp-coling2022
  selected: true
  group: intl-conference
  title: "GRASP: Guiding model with RelAtional Semantics using Prompt"
  url: https://aclanthology.org/2022.coling-1.33/
  venue: "The 29th International Conference on Computational Linguistics (COLING 2022)"
  venue_short: COLING
  year: 2022
  tags: [oral]
  authors:
    - { name: Junyoung Son, me: true, equal: true }
    - { name: Jinsung Kim, equal: true }
    - { name: Jungwoo Lim, equal: true }
    - { name: Heuiseok Lim }

- id: patents-ieee2022
  selected: true
  group: intl-journal
  title: "AI for Patents: A Novel yet Effective and Efficient Framework for Patent Analysis"
  url: https://ieeexplore.ieee.org/document/9779775
  venue: "IEEE Access, vol. 10, pp. 59205-59218, 2022"
  venue_short: IEEE Access
  year: 2022
  authors:
    - { name: Junyoung Son, me: true }
    - { name: Hyeonseok Moon }
    - { name: Jeongwoo Lee }
    - { name: Seolhwa Lee }
    - { name: Chanjun Park }
    - { name: Wonkyung Jung }
    - { name: Heuiseok Lim }

- id: komuret-hclt2025
  selected: false
  group: domestic
  title: "KomuRet: Korean Community-style Retrieval Benchmark"
  url: https://www.koreascience.kr/article/CFKO202533757619425.page
  venue: "Annual Conference on Human and Language Technology (HCLT 2025), pp. 619-624"
  venue_short: HCLT
  year: 2025
  authors:
    - { name: Junyoung Son, me: true }
    - { name: Youngjoon Jang }
    - { name: Taemin Lee }
    - { name: SeongTae Hong }
    - { name: Yuna Hur }
    - { name: Heuiseok Lim }
```

Full roster: 20 entries, file order = group order below, newest-first inside each group. Titles, URLs, venue strings, author names/order, `[*]` equal-contribution markers all verbatim from `git show 05a2a6d:index.md` (bold `**Junyoung Son**` → `me: true`; `[\*]` → `equal: true`).

| id | group | selected | venue_short | venue_note | tags | year |
|---|---|---|---|---|---|---|
| coref-rag-acl2025 | intl-conference | true | ACL | SRW | | 2025 |
| hyperbts-eacl2024 | intl-conference | | EACL | Findings | | 2024 |
| posthoc-emnlp2023 | intl-conference | true | EMNLP | | | 2023 |
| exploretheway-emnlp2023 | intl-conference | true | EMNLP | Findings | | 2023 |
| grasp-coling2022 | intl-conference | true | COLING | | oral | 2022 |
| kochet-coling2022 | intl-conference | | COLING | | | 2022 |
| promptlearner-applsci2023 | intl-journal | | Appl. Sci. | | | 2023 (flagged fix) |
| patents-ieee2022 | intl-journal | true | IEEE Access | | | 2022 |
| korean-ner-ieee2021 | intl-journal | | IEEE Access | | | 2021 |
| dbrag-hclt2025 | domestic | | HCLT | | | 2025 |
| kure-hclt2025 | domestic | true | HCLT | | | 2025 |
| komuret-hclt2025 | domestic | | HCLT | | | 2025 |
| mlmner-hclt2022 | domestic | | HCLT | | | 2022 |
| triggergen-hclt2022 | domestic | | HCLT | | | 2022 |
| persona-hclt2022 | domestic | | HCLT | | | 2022 |
| dialoguegraph-hclt2022 | domestic | | HCLT | | | 2022 |
| asrerror-hclt2021 | domestic | | HCLT | | | 2021 |
| segmentation-hclt2021 | domestic | | HCLT | | | 2021 |
| segmentation-jkcs2021 | domestic | | JKCS | | | 2021 |
| crosslingual-arxiv2025 | preprint | | arXiv | | | 2025 |

(`segmentation-jkcs2021` is the Domestic Journal entry "A Comparative study on the Effectiveness of Segmentation Strategies…", Journal of the Korea Convergence Society. `venue_note` may be omitted when empty; `tags` omitted when empty.)

- [ ] **Step 2: Write `_data/projects.yml`** (newest first; titles + periods verbatim, full list):

```yaml
- title: "독자 AI 파운데이션 모델 프로젝트: NCAI팀 데이터 리더"
  period: "2025.08.01 ~ 2025.12.31"
- title: "KURE: Korea University Retrieval Embedding Model 개발"
  period: "2024.08 ~ 2024.12"
- title: "벡터 임베딩 구축과 유사도 검색 원천기술 개발"
  period: "2024.01.01 ~ 2024.12.31"
- title: "영화 추천시스템 개발을 위한 메타데이터 증강 및 구조화 기술 개발"
  period: "2023.02 ~ 2023.05"
- title: "삼성 모바일 제품 디자인 분석 기술 개발"
  period: "2022.08 ~ 2022.12"
- title: "전문지식 대상 판단결과의 이유/근거를 설명가능한 전문가 의사 결정 지원 인공지능 기술개발: 기관 PM"
  period: "2021.04 ~ Present"
- title: "특허 문서의 발명 목적 문장 추출 및 Key phrase 추출 기술 개발"
  period: "2021.06.01 ~ 2021.10.31"
- title: "실감형 문화유산 체험을 위한 애셋 기반 지능형 큐레이션 및 서비스 운영기술 개발: 지식 기반 관계 네트워크 생성을 위한 텍스트 마이닝 연구"
  period: "2021.04.01 ~ 2022.12.31"
```

- [ ] **Step 3: Write the checker `scripts/check_data.rb`**

```ruby
#!/usr/bin/env ruby
require 'yaml'
pubs = YAML.load_file('_data/publications.yml')
projects = YAML.load_file('_data/projects.yml')
orig = `git show 05a2a6d:index.md`
fails = []

counts = pubs.group_by { |p| p['group'] }.transform_values(&:size)
fails << "group counts #{counts}" unless counts == {
  'intl-conference' => 6, 'intl-journal' => 3, 'domestic' => 10, 'preprint' => 1 }
fails << "selected != 6" unless pubs.count { |p| p['selected'] } == 6
fails << "projects != 8" unless projects.size == 8

pubs.each do |p|
  %w[id group title url venue venue_short year authors].each do |k|
    fails << "#{p['id']}: missing #{k}" if p[k].nil?
  end
  fails << "#{p['id']}: url not in original" unless orig.include?(p['url'])
  fails << "#{p['id']}: title not in original" unless orig.gsub(/\s+/, ' ').include?(p['title'].gsub(/\s+/, ' '))
  fails << "#{p['id']}: needs exactly one me:true" unless p['authors'].count { |a| a['me'] } == 1
  fails << "#{p['id']}: year not integer" unless p['year'].is_a?(Integer)
end
projects.each do |pr|
  fails << "project missing fields" if pr['title'].nil? || pr['period'].nil?
  fails << "project title/period not in original: #{pr['title'][0, 20]}" \
    unless orig.include?(pr['title']) && orig.include?(pr['period'])
end
ids = pubs.map { |p| p['id'] }
fails << "duplicate ids" unless ids.uniq == ids

if fails.empty? then puts 'PASS: data migration verified'
else fails.each { |f| puts "FAIL: #{f}" }; exit 1 end
```

- [ ] **Step 4: Run the checker**

Run: `ruby scripts/check_data.rb`
Expected: `PASS: data migration verified`. Fix YAML until it passes (the checker, not the YAML, is authoritative for coverage).

- [ ] **Step 5: Commit**

```bash
git add _data scripts/check_data.rb && git commit -m "feat: migrate publications and projects to data files"
```

---

### Task 3: Self-host fonts (STIX Two Text, IBM Plex Sans, IBM Plex Mono)

**Files:**
- Create: `assets/webfonts/*.woff2` (9 files), `_sass/_fonts.scss`, `scripts/fetch_fonts.py`

**Interfaces:**
- Produces: exact filenames consumed by Task 4's `head.html` preloads and imported by `main.scss`: `stix-two-text-400.woff2`, `stix-two-text-400i.woff2`, `stix-two-text-600.woff2`, `stix-two-text-700.woff2`, `ibm-plex-sans-400.woff2`, `ibm-plex-sans-500.woff2`, `ibm-plex-sans-600.woff2`, `ibm-plex-mono-400.woff2`, `ibm-plex-mono-600.woff2`.

- [ ] **Step 1: Write `scripts/fetch_fonts.py`** (stdlib only)

```python
#!/usr/bin/env python3
"""Download latin woff2 subsets from the Google Fonts CSS API."""
import re, urllib.request, pathlib

UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
CSS_URL = ("https://fonts.googleapis.com/css2?"
           "family=STIX+Two+Text:ital,wght@0,400;0,600;0,700;1,400"
           "&family=IBM+Plex+Sans:wght@400;500;600"
           "&family=IBM+Plex+Mono:wght@400;600&display=swap")
NAME = {"STIX Two Text": "stix-two-text", "IBM Plex Sans": "ibm-plex-sans",
        "IBM Plex Mono": "ibm-plex-mono"}
OUT = pathlib.Path("assets/webfonts")
OUT.mkdir(parents=True, exist_ok=True)

req = urllib.request.Request(CSS_URL, headers={"User-Agent": UA})
css = urllib.request.urlopen(req).read().decode()
blocks = re.findall(r"/\*\s*(\S+)\s*\*/\s*@font-face\s*\{(.*?)\}", css, re.S)
saved = []
for subset, body in blocks:
    if subset != "latin":
        continue
    family = re.search(r"font-family:\s*'([^']+)'", body).group(1)
    style = re.search(r"font-style:\s*(\w+)", body).group(1)
    weight = re.search(r"font-weight:\s*(\d+)", body).group(1)
    url = re.search(r"url\((\S+?\.woff2)\)", body).group(1)
    fname = f"{NAME[family]}-{weight}{'i' if style == 'italic' else ''}.woff2"
    data = urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA})).read()
    (OUT / fname).write_bytes(data)
    saved.append((fname, len(data)))
for fname, size in sorted(saved):
    print(f"{fname}  {size/1024:.0f} KB")
assert len(saved) == 9, f"expected 9 latin files, got {len(saved)}"
print("PASS: 9 latin woff2 files saved")
```

- [ ] **Step 2: Run it**

Run: `python3 scripts/fetch_fonts.py`
Expected: 9 files listed + `PASS`, total well under 220 KB (latin subsets run ~15-40 KB each). If Google Fonts is unreachable, STOP and ask the user (fallback per spec is keeping the Google `<link>`, which changes Task 4's head.html; do not decide silently).

- [ ] **Step 3: Verify files are real woff2**

Run: `file assets/webfonts/*.woff2 | grep -cv "Web Open Font Format.*2"`  → Expected: `0`
Run: `du -ch assets/webfonts/*.woff2 | tail -1` → Expected total < 220K (record the number).

- [ ] **Step 4: Write `_sass/_fonts.scss`**

```scss
@mixin face($family, $file, $weight, $style: normal) {
  @font-face {
    font-family: $family;
    src: url('/assets/webfonts/#{$file}.woff2') format('woff2');
    font-weight: $weight;
    font-style: $style;
    font-display: swap;
  }
}

@include face('STIX Two Text', 'stix-two-text-400', 400);
@include face('STIX Two Text', 'stix-two-text-400i', 400, italic);
@include face('STIX Two Text', 'stix-two-text-600', 600);
@include face('STIX Two Text', 'stix-two-text-700', 700);
@include face('IBM Plex Sans', 'ibm-plex-sans-400', 400);
@include face('IBM Plex Sans', 'ibm-plex-sans-500', 500);
@include face('IBM Plex Sans', 'ibm-plex-sans-600', 600);
@include face('IBM Plex Mono', 'ibm-plex-mono-400', 400);
@include face('IBM Plex Mono', 'ibm-plex-mono-600', 600);
```

- [ ] **Step 5: Commit**

```bash
git add assets/webfonts _sass/_fonts.scss scripts/fetch_fonts.py
git commit -m "feat: self-host STIX Two Text and IBM Plex woff2 subsets"
```

---

### Task 4: Template + SCSS cutover (the core)

**Files:**
- Create: `_layouts/home.html`, `_includes/hero.html`, `_includes/education.html`, `_includes/publications.html`, `_includes/author_line.html`, `_includes/projects.html`, `_sass/_tokens.scss`, `_sass/_base.scss`, `_sass/_nav.scss`, `_sass/_hero.scss`, `_sass/_publications.scss`, `_sass/_projects.scss`, `_sass/_footer.scss`
- Rewrite: `_includes/head.html`, `_layouts/base.html`, `_sass/main.scss`, `index.md`
- Delete: `_layouts/about.html`, `_sass/base/` (5 files), `_sass/layouts/` (5 files)
- Leave for Task 6: `_layouts/portfolio.html`, `_layouts/post.html`, `portfolio/index.html`, `_includes/icons.html`, Font Awesome assets

**Interfaces:**
- Consumes: `site.data.publications` / `site.data.projects` (Task 2 schema), font files + `_fonts.scss` (Task 3).
- Produces: class names consumed by Task 5's motion layer: `data-reveal` attributes, `.site-nav__links a` + `.is-active`, `.hero > .hero__text > *` children, section ids `about|publications|projects`.

- [ ] **Step 1: Rewrite `_includes/head.html`**

```html
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <title>{{ site.title }}</title>
  <meta name="description" content="Research portfolio of {{ site.author.name }}, {{ site.author.desc }}. Information Retrieval and Information Extraction.">
  <meta property="og:type" content="website">
  <meta property="og:title" content="{{ site.title }}">
  <meta property="og:description" content="Research portfolio of {{ site.author.name }}, {{ site.author.desc }}.">
  <meta property="og:url" content="{{ site.url }}/">
  <meta property="og:image" content="{{ site.url }}/{{ site.author.selfie }}">

  <link rel="preload" href="{{ '/assets/webfonts/stix-two-text-400.woff2' | relative_url }}" as="font" type="font/woff2" crossorigin>
  <link rel="preload" href="{{ '/assets/webfonts/stix-two-text-600.woff2' | relative_url }}" as="font" type="font/woff2" crossorigin>
  <link rel="preload" href="{{ '/assets/webfonts/ibm-plex-sans-400.woff2' | relative_url }}" as="font" type="font/woff2" crossorigin>
  <link rel="stylesheet" href="{{ '/assets/css/main.css' | relative_url }}">
  <link rel="icon" type="image/png" sizes="16x16" href="{{ '/assets/favicon.ico' | relative_url }}">

  {% if site.google_analytics %}
  <script>
      (function(i, s, o, g, r, a, m) {
          i['GoogleAnalyticsObject'] = r;
          i[r] = i[r] || function() {
              (i[r].q = i[r].q || []).push(arguments)
          }, i[r].l = 1 * new Date();
          a = s.createElement(o),
              m = s.getElementsByTagName(o)[0];
          a.async = 1;
          a.src = g;
          m.parentNode.insertBefore(a, m)
      })(window, document, 'script', '//www.google-analytics.com/analytics.js', 'ga');
      ga('create', '{{ site.google_analytics }}', 'auto');
      ga('send', 'pageview');
  </script>
  {% endif %}
</head>
```

- [ ] **Step 2: Rewrite `_layouts/base.html`**

```html
<!DOCTYPE html>
<html lang="en">

  {% include head.html %}

  <body>
    <nav class="site-nav" aria-label="Site">
      <div class="wrap site-nav__inner">
        <a class="site-nav__name" href="#top">{{ site.title }}</a>
        <ul class="site-nav__links">
          <li><a href="#about">About</a></li>
          <li><a href="#publications">Publications</a></li>
          <li><a href="#projects">Projects</a></li>
        </ul>
      </div>
    </nav>

    <main id="top">
      {{ content }}
    </main>

    <footer class="site-footer">
      <div class="wrap">
        <p>&copy; {{ site.time | date: '%Y' }} {{ site.author.name }} &middot; <a href="mailto:{{ site.author.email }}">{{ site.author.email }}</a></p>
      </div>
    </footer>
  </body>
</html>
```

- [ ] **Step 3: Create `_layouts/home.html`**

```html
---
layout: base
---
{% include hero.html %}

<section class="section" id="about" aria-labelledby="about-heading">
  <div class="wrap">
    <h2 class="section__heading" id="about-heading">About</h2>
    <div class="prose">{{ content }}</div>
    <ul class="chips" aria-label="Research interests">
      {% for term in page.interests %}<li class="chip">{{ term }}</li>{% endfor %}
    </ul>
    {% include education.html %}
  </div>
</section>

{% include publications.html %}
{% include projects.html %}
```

- [ ] **Step 4: Create `_includes/hero.html`**

```html
<header class="hero">
  <div class="wrap hero__inner">
    <div class="hero__text">
      <h1 class="hero__name">{{ site.author.name }}</h1>
      <p class="hero__statement">{{ page.statement_html }}</p>
      <p class="hero__affiliation">{{ page.affiliation_html }}</p>
      <ul class="hero__links">
        {% for l in page.links %}<li><a href="{{ l.url }}">{{ l.label }}</a></li>{% endfor %}
      </ul>
    </div>
    <img class="hero__photo" src="{{ site.author.selfie | prepend: '/' | relative_url }}"
         alt="Portrait of {{ site.author.name }}" width="200" height="250">
  </div>
</header>
```

- [ ] **Step 5: Create `_includes/education.html`**

```html
<dl class="edu">
  {% for e in page.education %}
  <div class="edu__row">
    <dt class="edu__degree">{{ e.degree }}</dt>
    <dd class="edu__inst">{{ e.institution }}</dd>
    <dd class="edu__period">{{ e.period }}</dd>
  </div>
  {% endfor %}
</dl>
```

- [ ] **Step 6: Create `_includes/publications.html`**

```html
<section class="section" id="publications" aria-labelledby="pubs-heading">
  <div class="wrap">
    <h2 class="section__heading" id="pubs-heading">Selected Publications</h2>
    <ol class="pubs-selected">
      {% for pub in site.data.publications %}{% if pub.selected %}
      {% assign first_author = pub.authors | first %}
      <li class="pub-card" data-reveal>
        <div class="pub-card__badge">
          <span class="badge-acronym">{{ pub.venue_short }}</span>
          {% if pub.venue_note %}<span class="badge-note">{{ pub.venue_note }}</span>{% endif %}
          {% if pub.tags contains 'oral' %}<span class="tag">Oral</span>{% endif %}
          {% if first_author.me %}<span class="tag">1st author</span>{% endif %}
        </div>
        <div class="pub-card__body">
          <a class="pub-title" href="{{ pub.url }}">{{ pub.title }}</a>
          <p class="pub-authors">{% include author_line.html authors=pub.authors %}</p>
        </div>
        <span class="pub-card__year">{{ pub.year }}</span>
      </li>
      {% endif %}{% endfor %}
    </ol>

    <h2 class="section__heading">All Publications</h2>
    {% assign group_keys = "intl-conference|intl-journal|domestic|preprint" | split: "|" %}
    {% assign group_names = "International Conference|International Journal|Domestic Conference &amp; Journal|Preprint" | split: "|" %}
    {% for gk in group_keys %}
    <div class="pub-group">
      <h3 class="pub-group__label">{{ group_names[forloop.index0] }}</h3>
      <ol class="pub-group__list">
        {% for pub in site.data.publications %}{% if pub.group == gk %}
        <li class="pub-row" data-reveal>
          <a class="pub-title" href="{{ pub.url }}">{{ pub.title }}</a>
          <p class="pub-row__meta">{{ pub.venue_short }}{% if pub.venue_note %} {{ pub.venue_note }}{% endif %} &middot; {{ pub.year }}</p>
          <p class="pub-authors">{% include author_line.html authors=pub.authors %}</p>
        </li>
        {% endif %}{% endfor %}
      </ol>
    </div>
    {% endfor %}
  </div>
</section>
```

- [ ] **Step 7: Create `_includes/author_line.html`** (shared by both lists)

```html
{% assign has_equal = false %}{% for a in include.authors %}{% if a.equal %}{% assign has_equal = true %}{% endif %}{% endfor %}{% for a in include.authors %}{% if a.me %}<strong class="me">{{ a.name }}</strong>{% else %}{{ a.name }}{% endif %}{% if a.equal %}*{% endif %}{% unless forloop.last %}, {% endunless %}{% endfor %}{% if has_equal %} <span class="equal-note">(*: equal contribution)</span>{% endif %}
```

(Single line on purpose so Liquid emits no stray whitespace inside the sentence.)

- [ ] **Step 8: Create `_includes/projects.html`**

```html
<section class="section" id="projects" aria-labelledby="projects-heading">
  <div class="wrap">
    <h2 class="section__heading" id="projects-heading">Projects</h2>
    <ul class="proj-grid">
      {% for p in site.data.projects %}
      <li class="proj-card" data-reveal>
        <p class="proj-card__title">{{ p.title }}</p>
        <p class="proj-card__period">{{ p.period }}</p>
      </li>
      {% endfor %}
    </ul>
  </div>
</section>
```

- [ ] **Step 9: Rewrite `index.md`**

```markdown
---
layout: home
statement_html: I&rsquo;m interested in <em>Information Retrieval</em> and <em>Information Extraction</em>.
affiliation_html: Graduate student, <a href="http://nlp.korea.ac.kr/">NLP &amp; AI Lab</a>, Korea University &middot; advised by Prof. <a href="https://scholar.google.co.kr/citations?user=HMTkz7oAAAAJ&hl=ko&oi=ao">Heuiseok Lim</a>
links:
  - { label: Google Scholar, url: "https://scholar.google.com/citations?user=ubIxtk8AAAAJ" }
  - { label: GitHub, url: "https://github.com/rgop13" }
  - { label: LinkedIn, url: "https://www.linkedin.com/in/junyoung-son-2836a2183/" }
  - { label: Email, url: "mailto:s0ny@korea.ac.kr" }
interests:
  - Information Extraction
  - Information Retrieval
  - Text Representation
  - Data Engineering
education:
  - { degree: "M.S & Ph.D in Computer Science & Engineering", institution: "Korea University", period: "2021/09 ~" }
  - { degree: "B.S in Information & Communication Engineering", institution: "Dongguk University", period: "2014/03 ~ 2021/02" }
---
I am a graduate student in Computer Science & Engineering at Korea University, advised by Prof. [Heuiseok Lim](https://scholar.google.co.kr/citations?user=HMTkz7oAAAAJ&hl=ko&oi=ao) in the [NLP & AI Lab](http://nlp.korea.ac.kr/). My research focuses on Information Retrieval and Information Extraction.

Contact: s0ny@korea.ac.kr / fnrnslwma@gmail.com

[//]: # (Please check my [CV]&#40;https://drive.google.com/file/d/1OIubJzknuk7bAkOjLuTYHHNBPVkzwjoe/view?usp=sharing&#41; and [Google Scholar]&#40;https://scholar.google.com/citations?user=ubIxtk8AAAAJ&hl=ko&#41;! )
```

(The last line preserves the original commented-out CV link per spec §11; it renders nothing.)

- [ ] **Step 10: Write the SCSS system.** `_sass/_tokens.scss`:

```scss
:root {
  --paper: #FCFCFA;
  --ink: #1B1B1F;
  --ink-soft: #50505A;
  --hairline: #E4E4E0;
  --accent: #8E2438;
  --accent-deep: #711C2D;
  --radius: 2px;
  --font-serif: 'STIX Two Text', 'Times New Roman', Times, serif;
  --font-sans: 'IBM Plex Sans', 'Apple SD Gothic Neo', 'Malgun Gothic', 'Helvetica Neue', sans-serif;
  --font-mono: 'IBM Plex Mono', Menlo, Monaco, monospace;
  --container: 880px;
  --section-pad: clamp(4rem, 9vh, 6.5rem);
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
}
```

`_sass/_base.scss`:

```scss
*,
*::before,
*::after { box-sizing: border-box; }

html {
  font-size: 17px;
}

@media (prefers-reduced-motion: no-preference) {
  html { scroll-behavior: smooth; }
}

body {
  margin: 0;
  background: var(--paper);
  color: var(--ink);
  font-family: var(--font-serif);
  line-height: 1.55;
  -webkit-text-size-adjust: 100%;
}

h1, h2, h3 {
  font-family: var(--font-serif);
  font-weight: 600;
  line-height: 1.15;
  margin: 0;
}

p { margin: 0 0 1rem; }

a {
  color: inherit;
  text-decoration: underline;
  text-decoration-color: var(--accent);
  text-decoration-thickness: 1px;
  text-underline-offset: 2px;
  transition: color 0.2s ease;
}

a:hover { color: var(--accent); }

:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}

::selection { background: var(--accent); color: var(--paper); }

img { max-width: 100%; display: block; }

ol, ul, dl { margin: 0; padding: 0; }
li { list-style: none; }

.wrap {
  max-width: var(--container);
  margin: 0 auto;
  padding-inline: clamp(1.25rem, 5vw, 2.5rem);
}

section[id] { scroll-margin-top: 5rem; }

.section { padding-block: var(--section-pad); }

.section__heading {
  font-size: 1.6rem;
  border-bottom: 1px solid var(--hairline);
  padding-bottom: 0.75rem;
  margin-bottom: 2rem;
}

.section__heading + .section__heading,
.pub-group + .section__heading { margin-top: 4rem; }

.prose {
  max-width: 70ch;

  em { font-style: italic; }
}

.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin: 1.5rem 0 2.5rem;
}

.chip {
  font-family: var(--font-sans);
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--ink-soft);
  border: 1px solid var(--hairline);
  border-radius: var(--radius);
  padding: 0.3rem 0.7rem;
}

.edu { max-width: 70ch; }

.edu__row {
  display: grid;
  grid-template-columns: 1fr auto;
  grid-template-areas: 'degree period' 'inst period';
  border-bottom: 1px solid var(--hairline);
  padding-block: 0.9rem;
}

.edu__degree {
  grid-area: degree;
  font-family: var(--font-sans);
  font-weight: 600;
  font-size: 0.95rem;
}

.edu__inst {
  grid-area: inst;
  margin: 0;
  font-family: var(--font-sans);
  font-size: 0.9rem;
  color: var(--ink-soft);
}

.edu__period {
  grid-area: period;
  align-self: center;
  margin: 0;
  font-family: var(--font-mono);
  font-size: 0.8rem;
  color: var(--ink-soft);
}
```

`_sass/_nav.scss`:

```scss
.site-nav {
  position: sticky;
  top: 0;
  z-index: 10; // only z-index on the page
  background: var(--paper);
  border-bottom: 1px solid var(--hairline);
}

.site-nav__inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  min-height: 3.5rem;
  gap: 0.25rem 1rem;
}

.site-nav__name {
  font-family: var(--font-serif);
  font-weight: 600;
  font-size: 1.05rem;
  text-decoration: none;
}

.site-nav__links {
  display: flex;
  gap: 1.4rem;
}

.site-nav__links a {
  font-family: var(--font-sans);
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--ink-soft);
  text-decoration: none;
}

.site-nav__links a:hover { color: var(--accent); }

.site-nav__links a.is-active { color: var(--accent); }

@media (max-width: 480px) {
  .site-nav__links { gap: 1rem; }
  .site-nav__links a { font-size: 0.8rem; }
}
```

`_sass/_hero.scss`:

```scss
.hero {
  padding-block: clamp(3.5rem, 8vh, 5.5rem);
  border-bottom: 1px solid var(--hairline);
}

.hero__inner {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 2.5rem;
  align-items: center;
}

.hero__name {
  font-size: clamp(2.75rem, 6vw, 4.25rem);
  line-height: 1.05;
  letter-spacing: -0.01em;
  margin-bottom: 1.25rem;
}

.hero__statement {
  font-size: 1.25rem;
  line-height: 1.55;
  max-width: 34ch;
  margin-bottom: 0.9rem;
}

.hero__affiliation {
  font-family: var(--font-sans);
  font-size: 0.95rem;
  color: var(--ink-soft);
  max-width: 55ch;
  margin-bottom: 1.6rem;
}

.hero__links {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem 1.5rem;
}

.hero__links a {
  font-family: var(--font-sans);
  font-size: 0.9rem;
  font-weight: 500;
  text-decoration: none;
  border-bottom: 1px solid var(--accent);
  padding-bottom: 1px;
}

.hero__photo {
  width: clamp(150px, 20vw, 200px);
  aspect-ratio: 4 / 5;
  object-fit: cover;
  border: 1px solid var(--hairline);
  border-radius: var(--radius);
}

@media (max-width: 767px) {
  .hero__inner {
    grid-template-columns: 1fr;
    gap: 1.75rem;
  }

  .hero__photo {
    width: 120px;
    order: -1;
  }
}
```

`_sass/_publications.scss`:

```scss
.pubs-selected { margin-bottom: 1rem; }

.pub-card {
  display: grid;
  grid-template-columns: 7.5rem 1fr auto;
  gap: 1.5rem;
  padding-block: 1.4rem;
  border-bottom: 1px solid var(--hairline);
}

.pub-card__badge {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.4rem;
}

.badge-acronym {
  font-family: var(--font-mono);
  font-weight: 600;
  font-size: 1.3rem;
  line-height: 1.1;
  text-transform: uppercase;
  letter-spacing: 0.02em;
}

.badge-note {
  font-family: var(--font-mono);
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--ink-soft);
}

.tag {
  font-family: var(--font-mono);
  font-weight: 600;
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--accent);
  border: 1px solid var(--accent);
  border-radius: var(--radius);
  padding: 0.1rem 0.45rem;
}

.pub-title {
  font-family: var(--font-serif);
  font-weight: 600;
  font-size: 1.125rem;
  line-height: 1.4;
  text-decoration: none;
  display: inline-block;
  margin-bottom: 0.45rem;
}

.pub-title:hover { color: var(--accent); }

.pub-authors {
  font-family: var(--font-sans);
  font-size: 0.9rem;
  line-height: 1.5;
  color: var(--ink-soft);
  margin: 0;

  .me { color: var(--ink); font-weight: 600; }

  .equal-note { font-size: 0.8rem; }
}

.pub-card__year {
  font-family: var(--font-mono);
  font-size: 0.85rem;
  color: var(--ink-soft);
  padding-top: 0.2rem;
}

.pub-group { margin-bottom: 2.5rem; }

.pub-group__label {
  font-family: var(--font-mono);
  font-weight: 400;
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--ink-soft);
  margin-bottom: 0.4rem;
}

.pub-row {
  padding-block: 1.1rem;
  border-bottom: 1px solid var(--hairline);
}

.pub-row__meta {
  font-family: var(--font-mono);
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--ink-soft);
  margin: 0 0 0.35rem;
}

@media (max-width: 639px) {
  .pub-card {
    grid-template-columns: 1fr;
    gap: 0.6rem;
  }

  .pub-card__badge {
    flex-direction: row;
    align-items: center;
  }

  .pub-card__year { padding-top: 0; }
}
```

`_sass/_projects.scss`:

```scss
.proj-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.25rem;
}

.proj-card {
  border: 1px solid var(--hairline);
  border-radius: var(--radius);
  padding: 1.25rem 1.4rem;
}

.proj-card__title {
  font-family: var(--font-sans);
  font-weight: 600;
  font-size: 0.95rem;
  line-height: 1.5;
  margin-bottom: 0.7rem;
}

.proj-card__period {
  font-family: var(--font-mono);
  font-size: 0.8rem;
  color: var(--ink-soft);
  margin: 0;
}

@media (max-width: 767px) {
  .proj-grid { grid-template-columns: 1fr; }
}
```

`_sass/_footer.scss`:

```scss
.site-footer {
  border-top: 1px solid var(--hairline);
  padding-block: 2.5rem;
}

.site-footer p {
  font-family: var(--font-sans);
  font-size: 0.85rem;
  color: var(--ink-soft);
  margin: 0;
}
```

`_sass/main.scss` (full replacement):

```scss
@import 'tokens';
@import 'fonts';
@import 'base';
@import 'nav';
@import 'hero';
@import 'publications';
@import 'projects';
@import 'footer';
```

(`_sass/_sections.scss` is not needed; section/chips/edu styles live in `_base.scss`. Do not create it.)

- [ ] **Step 11: Delete replaced files**

```bash
git rm _layouts/about.html
git rm -r _sass/base _sass/layouts
```

- [ ] **Step 12: Build**

Run: `$JEKYLL_BUILD` (from Task 1)
Expected: clean build. Common failures: Liquid syntax in includes, SCSS import name mismatch. Fix until clean.

- [ ] **Step 13: Screenshot review loop**

```bash
(cd _site && python3 -m http.server 4123 &) && sleep 1
npx playwright screenshot --viewport-size=1440,1000 --full-page http://localhost:4123/ .omc/shots/v1-desktop.png
npx playwright screenshot --viewport-size=768,1024  --full-page http://localhost:4123/ .omc/shots/v1-tablet.png
npx playwright screenshot --viewport-size=390,844   --full-page http://localhost:4123/ .omc/shots/v1-mobile.png
pkill -f "http[.]server 4123"
```

View all three (Read tool) and check against the spec §4: left-aligned hero with photo right (desktop) / photo above name (mobile); selected cards show badge column + crimson tags; hairline rows single-border; nav one line at all three widths; Korean project titles render in sans (Gothic). Iterate SCSS + re-shoot until it matches. Typical polish passes: spacing rhythm, badge column alignment, hero photo crop.

- [ ] **Step 14: Commit**

```bash
git add -A && git commit -m "feat: editorial academic redesign (templates, SCSS, data-driven content)"
```

---

### Task 5: Motion layer

**Files:**
- Create: `assets/js/reveal.js`, `_sass/_motion.scss`
- Modify: `_sass/main.scss` (add import), `_layouts/base.html` (script tag)

**Interfaces:**
- Consumes: `[data-reveal]` elements, `.site-nav__links a`, section ids (Task 4).
- Produces: classes `.will-reveal`, `.revealed`, `.is-active`.

- [ ] **Step 1: Write `assets/js/reveal.js`**

```js
(function () {
  'use strict';
  if (!('IntersectionObserver' in window)) return;
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  // Scroll reveal: hidden state is applied only here, so no-JS users see everything.
  var items = document.querySelectorAll('[data-reveal]');
  items.forEach(function (el) { el.classList.add('will-reveal'); });
  var reveal = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        entry.target.classList.add('revealed');
        reveal.unobserve(entry.target);
      }
    });
  }, { rootMargin: '0px 0px -8% 0px', threshold: 0.1 });
  items.forEach(function (el) { reveal.observe(el); });

  // Nav active state
  var links = document.querySelectorAll('.site-nav__links a');
  var byId = {};
  links.forEach(function (a) { byId[a.getAttribute('href').slice(1)] = a; });
  var sections = document.querySelectorAll('section[id]');
  var active = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      var link = byId[entry.target.id];
      if (!link) return;
      if (entry.isIntersecting) {
        links.forEach(function (a) { a.classList.remove('is-active'); });
        link.classList.add('is-active');
      }
    });
  }, { rootMargin: '-40% 0px -55% 0px' });
  sections.forEach(function (s) { active.observe(s); });
})();
```

- [ ] **Step 2: Write `_sass/_motion.scss`**

```scss
@media (prefers-reduced-motion: no-preference) {
  .will-reveal {
    opacity: 0;
    transform: translateY(12px);
    transition:
      opacity 0.5s var(--ease-out),
      transform 0.5s var(--ease-out);
  }

  .revealed {
    opacity: 1;
    transform: none;
  }

  @keyframes rise {
    from { opacity: 0; transform: translateY(14px); }
    to { opacity: 1; transform: none; }
  }

  .hero__name { animation: rise 0.55s var(--ease-out) 0.05s backwards; }
  .hero__statement { animation: rise 0.55s var(--ease-out) 0.12s backwards; }
  .hero__affiliation { animation: rise 0.55s var(--ease-out) 0.19s backwards; }
  .hero__links { animation: rise 0.55s var(--ease-out) 0.26s backwards; }
  .hero__photo { animation: rise 0.55s var(--ease-out) 0.2s backwards; }
}
```

- [ ] **Step 3: Wire up** — append `@import 'motion';` as the last line of `_sass/main.scss`; add before `</body>` in `_layouts/base.html`:

```html
    <script src="{{ '/assets/js/reveal.js' | relative_url }}" defer></script>
```

- [ ] **Step 4: Build + verify motion three ways**

Run `$JEKYLL_BUILD`, serve on 4123, then:
1. Normal screenshot → below-fold pub rows may appear blank in a full-page shot only if reveal never fired; verify by a viewport screenshot after scroll: `npx playwright screenshot --viewport-size=1440,1000 http://localhost:4123/#projects .omc/shots/v2-projects.png` (rows must be visible).
2. Reduced motion: `npx playwright screenshot --reduced-motion=reduce --viewport-size=1440,1000 --full-page http://localhost:4123/ .omc/shots/v2-reduced.png` → everything visible, no hidden content.
3. No JS: `grep -c "will-reveal" _site/index.html` → Expected `0` (class only added at runtime; static HTML never hides content).

- [ ] **Step 5: Commit**

```bash
git add assets/js/reveal.js _sass/_motion.scss _sass/main.scss _layouts/base.html
git commit -m "feat: scroll reveal, hero load-in, nav active state"
```

---

### Task 6: Cleanup (dead theme code, tracked _site, config)

**Files:**
- Delete: `_layouts/portfolio.html`, `_layouts/post.html`, `portfolio/index.html`, `_includes/icons.html`, `assets/css/fontawesome-all.min.css`, `.travis.yml`, Font Awesome files under `assets/webfonts/` (`fa-*` only; keep the 9 new woff2)
- Modify: `_config.yml`, `.gitignore`
- Untrack: `_site/`

- [ ] **Step 1: Confirm Font Awesome is unreferenced**

Run: `grep -rn "fontawesome\|icons.html" _layouts _includes index.md`
Expected: no hits (Task 4 removed all references). If any hit remains, fix it first.

- [ ] **Step 2: Delete dead files**

```bash
git rm _layouts/portfolio.html _layouts/post.html portfolio/index.html _includes/icons.html
git rm assets/css/fontawesome-all.min.css .travis.yml
git rm assets/webfonts/fa-brands-400.eot assets/webfonts/fa-brands-400.svg assets/webfonts/fa-brands-400.ttf assets/webfonts/fa-brands-400.woff assets/webfonts/fa-brands-400.woff2 2>/dev/null
ls assets/webfonts/  # then git rm every remaining fa-* / FontAwesome file listed (regular, solid variants)
```

(Use `ls` output to catch the exact Font Awesome filenames present; remove them all; the 9 Task 3 woff2 files stay.)

- [ ] **Step 3: Untrack `_site/`**

```bash
git rm -r --cached _site
printf '_site/\n' >> .gitignore
```

- [ ] **Step 4: Final `_config.yml`** (full replacement)

```yaml
# Site settings
title: Junyoung Son
baseurl: ""
url: "https://rgop13.github.io"
google_analytics: # Tracking ID, e.g. "UA-000000-01"

# Author
author:
  name: Junyoung Son
  desc: NLP & AI Lab., Korea University
  email: s0ny@korea.ac.kr
  selfie: assets/img/profile3.jpeg

# Build settings
markdown: kramdown

# Assets
sass:
  sass_dir: _sass
  style: compressed

exclude:
  - "Gemfile"
  - "Gemfile.lock"
  - "*.gem"
  - "LICENSE"
  - "README.md"
  - "CLAUDE.md"
  - "docs"
  - "scripts"
  - "vendor"
  - ".bundle"
  - "screenshot.png"
```

(Removed: `social:` block with 20 empty keys (hero links now live in index.md front matter), `plugins: [jekyll-paginate]`, `permalink:` and paginate comments. Added excludes: `scripts`, `vendor`, `.bundle`.)

- [ ] **Step 5: Rebuild and sanity-check**

Run `$JEKYLL_BUILD` → clean. Serve + one desktop screenshot → identical to Task 5 result. `ls _site/` → no `portfolio/`, no `2017-*` dirs (stale output regenerated away), `README.md`/`CLAUDE.md`/`docs` absent from `_site/`.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "chore: remove dead theme code, Font Awesome, tracked _site"
```

---

### Task 7: Full verification pass (pre-flight)

**Files:**
- Create: `scripts/check_rendered.rb`
- Fix anything the checks surface (SCSS/templates/data)

- [ ] **Step 1: Write `scripts/check_rendered.rb`**

```ruby
#!/usr/bin/env ruby
require 'yaml'
html = File.read('_site/index.html')
pubs = YAML.load_file('_data/publications.yml')
projects = YAML.load_file('_data/projects.yml')
fails = []

fails << "pub-title count != 26 (6 selected + 20 all)" unless html.scan('class="pub-title"').size == 26
fails << "proj-card count != 8" unless html.scan('class="proj-card"').size == 8
fails << "pub-card (selected) count != 6" unless html.scan('class="pub-card"').size == 6
pubs.each { |p| fails << "url missing in html: #{p['id']}" unless html.include?(p['url']) }
projects.each { |p| fails << "project missing: #{p['title'][0, 20]}" unless html.include?(p['title']) }
%w[about publications projects].each { |id| fails << "missing section ##{id}" unless html.include?("id=\"#{id}\"") }
dashes = html.scan(/[—–]/)
fails << "em/en dash found (#{dashes.size}); review each occurrence" unless dashes.empty?
fails << "old venue color leaked" if html.include?('73, 120, 173')
fails << "will-reveal leaked into static html" if html.include?('will-reveal')
fails << "focus-visible rule missing" unless File.read('_site/assets/css/main.css').include?('focus-visible')

if fails.empty? then puts 'PASS: rendered output verified'
else fails.each { |f| puts "FAIL: #{f}" }; exit 1 end
```

- [ ] **Step 2: Run it** — `ruby scripts/check_rendered.rb` → `PASS`. Fix and rebuild until it passes.

- [ ] **Step 3: Re-run data checker** — `ruby scripts/check_data.rb` → still `PASS`.

- [ ] **Step 4: Weight + performance sanity**

```bash
du -ch assets/webfonts/*.woff2 | tail -1        # < 220K
wc -c < _site/assets/css/main.css                # compressed CSS, expect < 20000
wc -c < _site/index.html                         # expect < 120000
```

- [ ] **Step 5: Visual pre-flight against the spec checklist** — final screenshots (desktop/tablet/mobile, plus `--reduced-motion=reduce`) into `.omc/shots/final-*.png`; view each and verify: one accent everywhere; single radius; nav ≤ 64px on one line; hero max 4 text elements; selected badges legible; no section eyebrows; Korean in Gothic sans; footer has no theme credit.

- [ ] **Step 6: Commit** (only if fixes were made)

```bash
git add -A && git commit -m "fix: verification pass adjustments"
```

---

### Task 8: Docs, push, live verification

**Files:**
- Modify: `CLAUDE.md` (conventions + gotchas sections)

- [ ] **Step 1: Update `CLAUDE.md`** — replace the "Content Conventions (index.md)" section with:

```markdown
## Content Conventions

Publications and projects are data-driven. To add or edit:

- `_data/publications.yml` — one entry per paper: `id`, `group` (intl-conference | intl-journal | domestic | preprint), `title`, `url`, `venue`, `venue_short`, optional `venue_note` (e.g. Findings, SRW), `year`, optional `tags` ([oral], [award]), `authors` (list of `{name, me: true, equal: true}`; exactly one `me`). Newest first within each group. Set `selected: true` (keep it to ~6) to feature an entry in Selected Publications with its venue badge.
- `_data/projects.yml` — `title` (Korean kept as-is), `period`. Newest first.
- Hero statement/links/interests/education live in `index.md` front matter; About prose is the markdown body.
- Design tokens (colors, fonts, spacing) live in `_sass/_tokens.scss`; fonts are self-hosted woff2 in `assets/webfonts/`.
- Verification: `ruby scripts/check_data.rb` (data vs original content) and `ruby scripts/check_rendered.rb` (built HTML) after `jekyll build`.
```

Also update the "Gotchas" section: `_site/` is now git-ignored (still never edit it); delete the bullet about the empty Portfolio page (removed in the redesign); note the site is one page with anchor nav.

- [ ] **Step 2: Commit docs**

```bash
git add CLAUDE.md && git commit -m "docs: update CLAUDE.md for data-driven redesign workflow"
```

- [ ] **Step 3: USER CHECKPOINT — confirm before push.** Pushing deploys the redesign live at rgop13.github.io. Show the user the final desktop + mobile screenshots and the two flagged content fixes (Task 2). Push only on explicit OK:

```bash
git push origin main
```

- [ ] **Step 4: Verify live**

```bash
sleep 90
curl -s -o /dev/null -w "%{http_code}" https://rgop13.github.io/          # 200
curl -s https://rgop13.github.io/ | grep -c "pub-title"                    # 26
npx playwright screenshot --viewport-size=1440,1000 --full-page https://rgop13.github.io/ .omc/shots/live-desktop.png
```

View the live screenshot; confirm fonts load (serif hero name, not Times fallback with wrong metrics) and report completion with before/after screenshots to the user.
