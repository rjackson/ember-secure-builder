require 'uri'
require 'json'
require 'spec_helper'

module EmberSecureBuilder
  describe RackApp do
    include Rack::Test::Methods


    def app
      RackApp
    end

    before do
      worker.jobs.clear
    end

    describe "POST /build" do
      let(:worker) { AssetBuildingWorker }

      it "should not add job to queue when no payload was received" do
        post '/build'

        refute last_response.ok?

        assert_equal 0, worker.jobs.size
        assert_equal 0, worker.jobs.size
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
          assert_equal 0, worker.jobs.size
        end
      end

      describe "with a valid payload" do
        before do
          post '/build', repo: 'emberjs/ember.js',
            pull_request_number: '3516',
            perform_cross_browser_tests: 'true'

          assert last_response.ok?
        end

        it "should queue a worker" do

          assert_equal 1, worker.jobs.size
        end

        it "should provide the correct arguments to the queued worker" do
          expected = ["emberjs/ember.js", "3516", true]

          job = worker.jobs.first

          assert_equal expected, job['args']
        end
      end
    end

    describe "POST /queue-browser-tests" do
      let(:worker) { SauceLabsWorker }
      let(:valid_params) do
        {'repo' => 'emberjs/ember.js',
         'project_name' => 'Ember',
         'tags' => 'ember',
         'commit_sha' => SecureRandom.urlsafe_base64,
         'test_url' => 'https://example.com/foo/bar/baz',
         'results_path' => 'foo/bar/baz'}
      end

      it "should not add job to queue when no payload was received" do
        post '/queue-browser-tests'

        refute last_response.ok?

        assert_equal 0, worker.jobs.size
        assert_equal 0, worker.jobs.size
      end

      describe "with a valid payload" do
        before do
          post '/queue-browser-tests', valid_params

          assert last_response.ok?
        end

        it "should queue a worker" do
          assert_equal SauceLabsWebdriverJob.default_platforms.length, worker.jobs.size
        end

        it "should provide the correct arguments to the queued worker" do
          worker.jobs.each do |job|
            args = job['args'].first

            assert_equal valid_params['test_url'], args['url']
            assert_equal valid_params['project_name'], args['name']
            assert_equal valid_params['tags'], args['tags']
            assert_equal valid_params['commit_sha'], args['build']
            assert_equal valid_params['results_path'], args['results_path']
          end
        end
      end
    end
  end
end
