require 'sidekiq'
require 'sidekiq/testing'
require 'minitest/autorun'
require_relative '../lib/github_post_receive_server'

$TESTING = true
