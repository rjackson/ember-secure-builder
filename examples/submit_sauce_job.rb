require 'dotenv'
Dotenv.load

require './lib/ember_secure_builder'

url = "https://s3.amazonaws.com/rwjblue-ember-dev-test/canary/shas/e1677e0b33b8f22488d9798244e1364a8ecef961/tests.html?qunit-filter-pass=true"

sauce = EmberSecureBuilder::SauceLabsJob.new test_url: url, os: 'Windows 7', browser: 'iehta', browser_version: '10'

sauce.submit_job
sauce.wait_for_completion
sauce.update_job_details

require 'pry'
binding.pry
