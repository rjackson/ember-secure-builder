ENV['RACK_ENV'] ||= 'test'

require 'sidekiq'
require 'sidekiq/testing'
require 'minitest/autorun'
require 'webmock/minitest'
require 'rack/test'
require_relative '../lib/ember_secure_builder'

