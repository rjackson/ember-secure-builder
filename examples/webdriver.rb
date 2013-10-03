require 'pry'
require 'dotenv'
Dotenv.load

require_relative '../lib/ember_secure_builder'

BUILD = '90eec26f8c3f930768d9622643dbd8c75f1b7b45'
URL = "https://s3.amazonaws.com/rwjblue-ember-dev-test/canary/shas/#{BUILD}/tests.html"

RUNS = [{:browser => :chrome,            :platform => 'OS X 10.8'},
        {:browser => :safari,            :platform => 'OS X 10.8', :version => 6},
        {:browser => :firefox,           :platform => 'Windows 7', :version => 23},
        {:browser => :internet_explorer, :platform => 'Windows 7', :version => 10},
        {:browser => :internet_explorer, :platform => 'Windows 7', :version => 9},
        {:browser => :internet_explorer, :platform => 'Windows 7', :version => 8},
        {:browser => :internet_explorer, :platform => 'Windows XP', :version => 7},
        {:browser => :internet_explorer, :platform => 'Windows XP', :version => 6}]

def run_all
  RUNS.each do |hash|
    EmberSecureBuilder::SauceLabsWorker.perform_async(hash.merge(:url => URL, :build => BUILD, :name => 'Ember Test Run'))
  end
end

def run_one(browser, version)

  hash = RUNS.find{|h| h[:browser] == browser && h[:version] == version }
  EmberSecureBuilder::SauceLabsWebdriverJob.new(hash.merge(:url => URL, :build => BUILD, :name => 'Ember Test Run'))
end

if __FILE__ == $PROGRAM_NAME

  sauce = run_one(:internet_explorer, 6)
  binding.pry
end
