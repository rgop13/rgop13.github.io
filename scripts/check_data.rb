#!/usr/bin/env ruby
require 'yaml'
pubs = YAML.load_file('_data/publications.yml')
projects = YAML.load_file('_data/projects.yml')
fails = []

counts = pubs.group_by { |p| p['group'] }.transform_values(&:size)
fails << "group counts #{counts}" unless counts == {
  'intl-conference' => 7, 'intl-journal' => 3, 'domestic' => 11, 'preprint' => 1 }
fails << "no selected publications" unless pubs.any? { |p| p['selected'] }
fails << "projects != 8" unless projects.size == 8

pubs.each do |p|
  %w[id group title url venue venue_short year authors].each do |k|
    fails << "#{p['id']}: missing #{k}" if p[k].nil?
  end
  fails << "#{p['id']}: url must use https" unless p['url'].to_s.match?(%r{\Ahttps://})
  fails << "#{p['id']}: selected must be boolean" unless [true, false].include?(p['selected'])
  fails << "#{p['id']}: needs exactly one me:true" unless p['authors'].count { |a| a['me'] } == 1
  fails << "#{p['id']}: year not integer" unless p['year'].is_a?(Integer)
end
projects.each_with_index do |pr, index|
  label = pr['title'] || "project ##{index + 1}"
  %w[title period role purpose overview].each do |key|
    fails << "#{label}: missing #{key}" if pr[key].nil? || pr[key].to_s.strip.empty?
  end
  fails << "#{label}: learnings must be an array" unless pr['learnings'].is_a?(Array)
  fails << "#{label}: stack must not be empty" unless pr['stack'].is_a?(Array) && !pr['stack'].empty?
  fails << "#{label}: links must be an array" unless pr['links'].is_a?(Array)
  Array(pr['links']).each do |link|
    fails << "#{label}: invalid link" unless link.is_a?(Hash) &&
      !link['label'].to_s.strip.empty? && link['url'].to_s.match?(%r{\Ahttps://})
  end
end
ids = pubs.map { |p| p['id'] }
fails << "duplicate ids" unless ids.uniq == ids
project_titles = projects.map { |pr| pr['title'] }
fails << "duplicate project titles" unless project_titles.uniq == project_titles

if fails.empty? then puts 'PASS: data migration verified'
else fails.each { |f| puts "FAIL: #{f}" }; exit 1 end
