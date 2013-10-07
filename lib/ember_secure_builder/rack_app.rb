require 'rack'
require 'json'
require 'sinatra'

module EmberSecureBuilder
  class RackApp < Sinatra::Base
    post '/build' do
      repo                        = params['repo']
      pull_request_number         = params['pull_request_number']
      perform_cross_browser_tests = params['perform_cross_browser_tests'] == 'true'

      halt 400 unless repo && pull_request_number
      halt 403 unless %w{emberjs/ember.js emberjs/data}.include? repo

      AssetBuildingWorker.perform_async(repo, pull_request_number, perform_cross_browser_tests)
    end
  end
end
