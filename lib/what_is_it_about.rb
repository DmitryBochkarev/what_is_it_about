require 'rubygems'
require 'bundler'
require 'yaml'
require 'open-uri'
require 'json'
require 'pry'

# for parsing gemfile lock
ENV['BUNDLE_GEMFILE'] = Pathname.new(Dir.pwd).join(__FILE__).to_s

module WhatIsItAbout
end

require 'what_is_it_about/version'
require 'what_is_it_about/config'
require 'what_is_it_about/github'
require 'what_is_it_about/gem_summary'
require 'what_is_it_about/summary'
require 'what_is_it_about/report'
