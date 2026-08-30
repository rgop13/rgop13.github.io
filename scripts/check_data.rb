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
