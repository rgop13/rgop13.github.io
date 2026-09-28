#!/usr/bin/env ruby
require 'yaml'
html = File.read('_site/index.html')
pubs = YAML.load_file('_data/publications.yml')
projects = YAML.load_file('_data/projects.yml')
fails = []

selected_count = pubs.count { |p| p['selected'] }
expected_title_count = pubs.size + selected_count
fails << "pub-title count != #{expected_title_count}" unless html.scan('class="pub-title"').size == expected_title_count
fails << "proj-card count != 8" unless html.scan('class="proj-card"').size == 8
fails << "pub-card (selected) count != #{selected_count}" unless html.scan('class="pub-card"').size == selected_count
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
