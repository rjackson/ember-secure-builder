require 'rack'
require 'json'
require 'sinatra'

module EmberSecureBuilder
  class RackApp < Sinatra::Base

    def handle_request(payload)
      puts payload unless $TESTING # remove me!

      payload           = JSON.parse(payload)
      source_repository = payload['pull_request']['head']['repo']['ssh_url']
      source_branch     = payload['pull_request']['head']['ref']

      AssetBuildingWorker.perform_async(source_repository, source_branch)
    end

    post '/build' do
      repo                        = params['repo']
      pull_request_number         = params['pull_request_number']
      perform_cross_browser_tests = params['perform_cross_browser_tests']

      halt 400 unless repo && pull_request_number

      AssetBuildingWorker.perform_async(repo, pull_request_number, perform_cross_browser_tests)
    end
  end
end
