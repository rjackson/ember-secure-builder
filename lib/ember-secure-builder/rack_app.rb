#
#  rack_app.rb
#  github_post_commit_server
#
#  Example Rack app for http://github.com/guides/post-receive-hooks
#
#  Created by James Tucker on 2008-05-11.
#  Copyright 2008 James Tucker
#

require 'rack'
require 'json'

module EmberSecureBuilder
  class RackApp

    # Does what it says on the tin. By default, not much, it just prints the
    # received payload.
    def handle_request(payload)
      puts payload unless $TESTING # remove me!

      payload           = JSON.parse(payload)
      source_repository = payload['pull_request']['head']['repo']['ssh_url']
      source_branch     = payload['pull_request']['head']['ref']

      AssetBuildingWorker.perform_async(source_repository, source_branch)
    end

    # Call is the entry point for all rack apps.
    def call(env)
      @req = Rack::Request.new(env)
      @res = Rack::Response.new

      payload = @req.POST["payload"]

      handle_request(payload) if payload

      @res.finish
    end
  end
end
