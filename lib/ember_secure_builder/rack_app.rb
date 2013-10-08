require 'rack'
require 'json'
require 'sinatra'

module EmberSecureBuilder
  class RackApp < Sinatra::Base
    before do
      halt 403 unless %w{emberjs/ember.js emberjs/data}.include? params['repo']
    end

    post '/build' do
      repo                        = params['repo']
      pull_request_number         = params['pull_request_number']
      perform_cross_browser_tests = params['perform_cross_browser_tests'] == 'true'

      halt 400 unless repo && pull_request_number
      halt 403 unless %w{emberjs/ember.js emberjs/data}.include? repo

      AssetBuildingWorker.perform_async(repo, pull_request_number, perform_cross_browser_tests)
    end

    post '/queue-browser-tests' do
      repo         = params['repo']
      name         = params['project_name']
      tags         = params['tags']
      build        = params['commit_sha']
      test_url     = params['test_url']
      results_path = params['results_path']

      halt 400 unless repo && build && test_url

      options = { test_options: { url: test_url,
                                  name: name,
                                  tags: tags,
                                  build: build,
                                  results_path: results_path} }

      workers = SauceLabsWorker.queue_cross_browser_tests options
      workers.to_json
    end
  end
end
