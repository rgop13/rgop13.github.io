#!/usr/bin/env ruby
# Generates a submission-ready CV from the site's data into _cv/: <Name>_CV.md, .html, .pdf (A4).
# Usage (from the repo root): bundle exec ruby scripts/build_cv.rb
require 'yaml'
require 'cgi'
require 'base64'
require 'kramdown'
require 'fileutils'
require 'open-uri'

ROOT = File.expand_path('..', __dir__)
OUT = File.join(ROOT, '_cv')
FONT_DIR = File.join(OUT, 'fonts')
FileUtils.mkdir_p(FONT_DIR)

# Static (non-variable) OFL fonts that cover Latin + Hangul, so Chromium embeds real TrueType
# fonts and the PDF text layer stays extractable by HR/ATS parsers. Variable fonts and macOS
# system Hangul fonts come out as Type 3, which garbles extracted text.
FONTS = {
  'IBMPlexSansKR-Regular.woff2' => 'https://cdn.jsdelivr.net/npm/@ibm/plex-sans-kr@1.1.0/fonts/complete/woff2/hinted/IBMPlexSansKR-Regular.woff2',
  'IBMPlexSansKR-SemiBold.woff2' => 'https://cdn.jsdelivr.net/npm/@ibm/plex-sans-kr@1.1.0/fonts/complete/woff2/hinted/IBMPlexSansKR-SemiBold.woff2',
  'IBMPlexSerif-SemiBold.woff2' => 'https://cdn.jsdelivr.net/npm/@ibm/plex-serif@2.0.0/fonts/complete/woff2/IBMPlexSerif-SemiBold.woff2',
}.freeze
FONTS.each do |file, url|
  path = File.join(FONT_DIR, file)
  next if File.exist?(path)
  File.binwrite(path, URI.open(url, &:read))
end

site = YAML.load_file(File.join(ROOT, '_config.yml'))
pubs = YAML.load_file(File.join(ROOT, '_data/publications.yml'))
projects = YAML.load_file(File.join(ROOT, '_data/projects.yml'))
index_src = File.read(File.join(ROOT, 'index.md'))
_, front_raw, body = index_src.split(/^---\s*$/, 3)
front = YAML.safe_load(front_raw)

def plain(html)
  CGI.unescapeHTML(html.to_s.gsub(/<[^>]+>/, '').gsub('&middot;', '·').gsub('&rsquo;', "'"))
end

def blank?(value)
  value.nil? || (value.respond_to?(:empty?) && value.empty?) || value.to_s.strip.empty?
end

# data fields are plain text; keep markdown from reinterpreting them (overview is markdown by schema)
def esc(text)
  text.to_s.gsub(/([\\*_\[\]`])/) { "\\#{Regexp.last_match(1)}" }
end

def short_url(url)
  url.sub(%r{\Ahttps?://}, '').sub(/\Awww\./, '').chomp('/')
end

author = site['author']
base = "#{author['name'].delete(' ')}_CV"
summary = body.split(/\n\s*\n/).map(&:strip)
              .reject { |para| para.empty? || para.start_with?('Contact:') || para.start_with?('[//]:') }
              .first
emails = body[/^Contact:\s*(.+)$/, 1].to_s.split('/').map(&:strip).reject(&:empty?)
emails = [author['email']] if emails.empty?
links = [['Website', site['url']]] +
        front['links'].reject { |l| l['url'].start_with?('mailto:') }.map { |l| [l['label'], l['url']] }

md = []
md << "# #{esc(author['name'])}"
md << ''
md << esc(plain(front['affiliation_html']))
md << ''
md << emails.map { |e| esc(e) }.join(' · ')
md << ''
md << links.map { |label, url| "[#{esc(url.include?('?') ? label : short_url(url))}](#{url})" }.join(' · ')
md << ''

md << '## Summary'
md << ''
md << summary
md << ''

md << '## Education'
md << ''
front['education'].each do |e|
  md << "- **#{esc(e['degree'])}**, #{esc(e['institution'])} (#{esc(e['period'])})"
end
md << ''

md << '## Research Interests'
md << ''
md << front['interests'].map { |i| esc(i) }.join(', ')
md << ''

md << '## Projects'
md << ''
projects.each do |p|
  md << "### #{esc(p['title'])}"
  md << ''
  md << esc(p['period'])
  md << ''
  [['Role', p['role']], ['Purpose', p['purpose']]].each do |label, value|
    next if blank?(value)
    md << "**#{label}.** #{esc(value)}"
    md << ''
  end
  unless blank?(p['overview'])
    md << p['overview'].strip
    md << ''
  end
  unless blank?(p['learnings'])
    md << '**Learnings.**'
    md << ''
    p['learnings'].each { |item| md << "- #{esc(item)}" }
    md << ''
  end
  unless blank?(p['stack'])
    md << "**Keywords.** #{p['stack'].map { |s| esc(s) }.join(', ')}"
    md << ''
  end
  unless blank?(p['links'])
    md << "**Links.** #{p['links'].map { |l| "[#{esc(l['label'])}](#{l['url']})" }.join(' · ')}"
    md << ''
  end
end

GROUPS = [
  ['intl-conference', 'International Conference'],
  ['intl-journal', 'International Journal'],
  ['domestic', 'Domestic Conference & Journal'],
  ['preprint', 'Preprint'],
].freeze

md << '## Publications'
md << ''
md << '\* equal contribution'
md << ''
GROUPS.each do |key, name|
  group = pubs.select { |p| p['group'] == key }
  next if group.empty?
  md << "### #{name}"
  md << ''
  group.each do |p|
    authors = p['authors'].map do |a|
      name_md = a['me'] ? "**#{esc(a['name'])}**" : esc(a['name'])
      a['equal'] ? "#{name_md}\\*" : name_md
    end.join(', ')
    venue = p['venue'].to_s
    venue = "#{venue}, #{p['year']}" unless venue.match?(/\b#{p['year']}\b/)
    oral = Array(p['tags']).include?('oral') ? ' **(Oral)**' : ''
    md << "- [#{esc(p['title'])}](#{p['url']}). #{authors}. *#{esc(venue)}*.#{oral}"
  end
  md << ''
end

md << "_Last updated: #{Time.now.strftime('%Y-%m-%d')}. Online version: [#{short_url(site['url'])}](#{site['url']})_"
md << ''

markdown = md.join("\n")
File.write(File.join(OUT, "#{base}.md"), markdown)

def font_face(family, file, weight)
  data = Base64.strict_encode64(File.binread(File.join(FONT_DIR, file)))
  "@font-face { font-family: '#{family}'; src: url(data:font/woff2;base64,#{data}) format('woff2'); font-weight: #{weight}; }"
end

fonts = [
  font_face('CV Sans', 'IBMPlexSansKR-Regular.woff2', 400),
  font_face('CV Sans', 'IBMPlexSansKR-SemiBold.woff2', 600),
  font_face('CV Serif', 'IBMPlexSerif-SemiBold.woff2', 600),
].join("\n")

css = <<~CSS
  #{fonts}
  @page {
    size: A4;
    margin: 15mm 16mm 16mm;
    @bottom-right { content: "#{author['name']}  ·  " counter(page) " / " counter(pages);
                    font-family: 'CV Sans'; font-size: 7.5pt; color: #50505A; }
  }
  :root { --ink: #1B1B1F; --soft: #50505A; --rule: #D6D6D2; --link: #D4AEB6; }
  html { font-size: 9.4pt; }
  body { margin: 0; color: var(--ink); line-height: 1.5; word-break: keep-all; overflow-wrap: break-word;
         font-family: 'CV Sans', sans-serif; }
  a { color: inherit; text-decoration: underline; text-decoration-color: var(--link);
      text-decoration-thickness: 0.6pt; text-underline-offset: 1.5pt; }
  h1 { font-family: 'CV Serif', serif; font-weight: 600; font-size: 22pt; line-height: 1.1; margin: 0 0 5pt; }
  h1 ~ p { margin: 0 0 1.5pt; color: var(--soft); }
  h2 { font-family: 'CV Serif', serif; font-weight: 600; font-size: 12.5pt; margin: 15pt 0 7pt;
       padding-bottom: 3pt; border-bottom: 0.75pt solid var(--rule); break-after: avoid; }
  h2 ~ p { color: var(--ink); margin: 0 0 5pt; }
  h3 { font-size: 10.2pt; font-weight: 600; margin: 11pt 0 1pt; line-height: 1.4; break-after: avoid; }
  .proj { break-inside: avoid; }
  .proj p { margin: 0 0 4pt; }
  .proj h3 + p { color: var(--soft); font-size: 8.8pt; letter-spacing: 0.02em; }
  h2 + .proj h3 { margin-top: 6pt; }
  ul { margin: 0 0 4pt; padding-left: 12pt; }
  li { margin-bottom: 3.5pt; break-inside: avoid; }
  strong { font-weight: 600; }
  p { orphans: 3; widows: 3; }
  body > p:last-child { margin-top: 16pt; color: var(--soft); font-size: 8.4pt; }
CSS

ascii_typography = { hellip: '...', mdash: '---', ndash: '--', laquo: '<<', raquo: '>>',
                     laquo_space: '<< ', raquo_space: ' >>' }
html_body = Kramdown::Document.new(markdown, auto_ids: false, smart_quotes: %w[apos apos quot quot],
                                             typographic_symbols: ascii_typography).to_html
# wrap each project in a block so the PDF never splits one project across pages
html_body = html_body.sub(%r{(<h2>Projects</h2>\n)(.*?)(?=<h2>)}m) do
  head = Regexp.last_match(1)
  blocks = Regexp.last_match(2).split(/(?=<h3>)/).reject { |b| b.strip.empty? }
  head + blocks.map { |b| %(<section class="proj">\n#{b}</section>\n) }.join
end
html = <<~HTML
  <!doctype html>
  <html lang="en">
  <head>
  <meta charset="utf-8">
  <title>#{author['name']} CV</title>
  <style>
  #{css}
  </style>
  </head>
  <body>
  #{html_body}
  </body>
  </html>
HTML
html_path = File.join(OUT, "#{base}.html")
File.write(html_path, html)

pdf_path = File.join(OUT, "#{base}.pdf")
ok = system('npx', 'playwright', 'pdf', '--paper-format', 'A4', '--wait-for-timeout', '800',
            'file://' + html_path.gsub(' ', '%20'), pdf_path, out: File::NULL)
abort 'PDF generation failed (is Playwright Chromium installed? npx playwright install chromium)' unless ok && File.exist?(pdf_path)
puts "wrote _cv/#{base}.md, _cv/#{base}.html, _cv/#{base}.pdf (#{File.size(pdf_path) / 1024} KB)"
