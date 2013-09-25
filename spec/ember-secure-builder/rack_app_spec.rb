require 'uri'
require 'spec_helper'

module EmberSecureBuilder
  describe RackApp do
    let(:server) { RackApp.new }
    let(:request) { Rack::MockRequest.new(server) }
    let(:mock_payload) { File.read('spec/support/sample_github_payload.json') }

    before do
      AssetBuildingWorker.jobs.clear
    end

    describe "should not add job to queue when no payload was received" do
      it "for get requests" do
        response = request.get("/")

        assert response.ok?
        assert_equal 0, AssetBuildingWorker.jobs.size
      end

      it "for post requests" do
        response = request.post("/", {})

        assert response.ok?
        assert_equal 0, AssetBuildingWorker.jobs.size
        assert_equal 0, AssetBuildingWorker.jobs.size
      end
    end

    describe "with a valid payload" do
      let(:post_body) { URI.encode_www_form(:payload => mock_payload) }
      let(:response) { request.post('/', :input => post_body) }

      before do
        assert response.ok?
      end

      it "should queue a AssetBuildingWorker" do
        assert_equal 1, AssetBuildingWorker.jobs.size
      end

      it "should provide the correct arguments to the queued worker" do
        expected = ["git@github.com:rjackson/ember-performance.git", "refactor_profilers"]

        job = AssetBuildingWorker.jobs.first

        assert_equal expected, job['args']
      end
    end
  end
end
