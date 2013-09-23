require 'uri'
require 'spec_helper'

module EmberSecureBuilder
  describe RackApp do
    let(:server) { RackApp.new }
    let(:request) { Rack::MockRequest.new(server) }
    let(:mock_payload) { File.read('spec/support/sample_github_payload.json') }

    after do
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

    it "should reply with a nice message on POST with a payload" do
      post_body = URI.encode_www_form(:payload => mock_payload)
      response = request.post("/", :input => post_body)

      assert response.ok?

      assert_equal 1, AssetBuildingWorker.jobs.size
    end
  end
end
