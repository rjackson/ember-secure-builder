ENV['RACK_ENV'] ||= 'test'

require 'pathname'
require 'sidekiq'
require 'sidekiq/testing'
require 'minitest/autorun'
require 'webmock/minitest'
require 'rack/test'
require_relative '../lib/ember_secure_builder'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["spec/support/**/*.rb"].each {|f| require Pathname.new(f).realpath.to_s}

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/support/vcr_cassettes'
  c.hook_into :webmock
end
