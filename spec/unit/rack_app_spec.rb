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

    describe "with an invalid repo" do
      before do
        post '/build', repo: 'boom/blah.js',
                       pull_request_number: 1,
                       perform_cross_browser_tests: 'true'

        refute last_response.ok?
      end

      it "should respond with 403" do
        assert_equal 403, last_response.status
      end

      it "should not queue any items" do
        assert_equal 0, AssetBuildingWorker.jobs.size
      end
    end

    describe "with a valid payload" do
      before do
        post '/build', repo: 'emberjs/ember.js',
                       pull_request_number: '3516',
                       perform_cross_browser_tests: 'true'

        assert last_response.ok?
      end

      it "should queue a AssetBuildingWorker" do

        assert_equal 1, AssetBuildingWorker.jobs.size
      end

      it "should provide the correct arguments to the queued worker" do
        expected = ["emberjs/ember.js", "3516", true]

        job = AssetBuildingWorker.jobs.first

        assert_equal expected, job['args']
      end
    end
  end
end
