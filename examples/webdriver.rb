require 'dotenv'
require 'octokit'
require 'rest-client'

Dotenv.load

pull_requests = Octokit.pull_requests 'emberjs/ember.js'
pull_requests.each do |pr|
  RestClient.post 'http://localhost:9292/build', repo: 'emberjs/ember.js', perform_cross_browser_tests: true, pull_request_number: pr.number
end

pull_requests = Octokit.pull_requests 'emberjs/data'
pull_requests.each do |pr|
  RestClient.post 'http://localhost:9292/build', repo: 'emberjs/data', perform_cross_browser_tests: true, pull_request_number: pr.number
end
