require 'sidekiq'
require 'sidekiq/testing'
require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../lib/ember_secure_builder'

$TESTING = true
