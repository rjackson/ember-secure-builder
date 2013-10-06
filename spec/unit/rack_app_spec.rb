require 'uri'
require 'spec_helper'

module EmberSecureBuilder
  describe RackApp do
    include Rack::Test::Methods

    def app
      RackApp
    end

    before do
      AssetBuildingWorker.jobs.clear
    end

    it "should not add job to queue when no payload was received" do
      post '/build'

      refute last_response.ok?

      assert_equal 0, AssetBuildingWorker.jobs.size
      assert_equal 0, AssetBuildingWorker.jobs.size
    end

    describe "with a valid payload" do
      before do
        post '/build', repo: 'emberjs/ember.js', pull_request_number: '3516'

        assert last_response.ok?
      end

      it "should queue a AssetBuildingWorker" do

        assert_equal 1, AssetBuildingWorker.jobs.size
      end

      it "should provide the correct arguments to the queued worker" do
        expected = ["emberjs/ember.js", "3516"]

        job = AssetBuildingWorker.jobs.first

        assert_equal expected, job['args']
      end
    end
  end
end
