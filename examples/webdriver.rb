require 'dotenv'
Dotenv.load

require_relative '../lib/ember_secure_builder'

build = 'e1677e0b33b8f22488d9798244e1364a8ecef961'
url = "https://s3.amazonaws.com/rwjblue-ember-dev-test/canary/shas/#{build}/tests.html?qunit-filter-pass=true"

runs = [{:browser => :chrome,            :platform => 'OS X 10.8'},
        {:browser => :safari,            :platform => 'OS X 10.8', :version => 6},
        {:browser => :firefox,           :platform => 'Windows 7', :version => 23},
        {:browser => :internet_explorer, :platform => 'Windows 7', :version => 10},
        {:browser => :internet_explorer, :platform => 'Windows 7', :version => 9},
        {:browser => :internet_explorer, :platform => 'Windows 7', :version => 8},
        {:browser => :internet_explorer, :platform => 'Windows XP', :version => 7},
        {:browser => :internet_explorer, :platform => 'Windows XP', :version => 6}]

runs.each do |hash|
  EmberSecureBuilder::SauceLabsWebdriverJob.run!(hash.merge(:url => url, :build => build, :name => 'Ember Test Run'))
end
