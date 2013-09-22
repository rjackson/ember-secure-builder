require 'rack'
require 'json'

module EmberSecureBuilder
  class RackApp

    def handle_request(payload)
      puts payload unless $TESTING # remove me!

      payload           = JSON.parse(payload)
      source_repository = payload['pull_request']['head']['repo']['ssh_url']
      source_branch     = payload['pull_request']['head']['ref']

      AssetBuildingWorker.perform_async(source_repository, source_branch)
    end

    def call(env)
      @req = Rack::Request.new(env)
      @res = Rack::Response.new

      payload = @req.POST["payload"]

      handle_request(payload) if payload

      @res.finish
    end
  end
end
