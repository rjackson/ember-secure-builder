require 'pry'
require 'dotenv'
Dotenv.load

require_relative '../lib/ember_secure_builder'

BUILD = '2985b2892d0a2c0b75bba7b5e1b5389251b7f1b4'
URL = "https://s3.amazonaws.com/rwjblue-ember-dev-test/canary/shas/#{BUILD}/ember-tests.html"

def run_all
  SauceLabsWebdriverJob.default_platforms.each do |hash|
    EmberSecureBuilder::SauceLabsWorker.perform_async(hash.merge(:url => URL, :build => BUILD, :name => 'Ember Test Run'))
  end
end

def run_one(browser, version)
  hash = SauceLabsWebdriverJob.all_platforms.find{|h| h[:browser] == browser && h[:version] == version }
  EmberSecureBuilder::SauceLabsWebdriverJob.new(hash.merge(:url => URL, :build => BUILD, :name => 'Ember Test Run'))
end

if __FILE__ == $PROGRAM_NAME
  sauce = run_one(:internet_explorer, 6)
  binding.pry
end
