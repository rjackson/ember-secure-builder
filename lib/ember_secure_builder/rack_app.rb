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

      AssetBuildingWorker.perform_async(repo, pull_request_number, perform_cross_browser_tests)
    end
  end
end
