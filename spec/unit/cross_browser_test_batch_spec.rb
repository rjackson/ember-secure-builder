require 'securerandom'
require 'spec_helper'

module EmberSecureBuilder
  describe CrossBrowserTestBatch do
    include TestSupport::RedisAssertion

    let(:batch) { CrossBrowserTestBatch.new options }
    let(:options)  do
      {
        :url   => url,
        :name  => name,
        :build => build,
        :tags  => tags,
        :redis => mock_redis,
        :platforms    => platforms,
        :results_path => results_path,
        :worker_class => mock_worker,
        :results_worker_class => mock_results_worker
      }
    end

    let(:mock_redis)   { TestSupport::MockRedis.new }
    let(:mock_worker)  { Minitest::Mock.new }
    let(:mock_results_worker) { Minitest::Mock.new }
    let(:url)          { "https://blahblah.com/something/#{SecureRandom.urlsafe_base64}" }
    let(:results_path) { SecureRandom.urlsafe_base64 }
    let(:job_name)     { SecureRandom.urlsafe_base64 }
    let(:platforms)    { [{browser: 'googlechrome', platform: 'Windows 7'},
                          {browser: 'firefox', platform: 'Windows 7', version: 24}] }
    let(:build)        { SecureRandom.urlsafe_base64 }
    let(:tags)         { [] }

    it "sets up attributes on init" do
      assert_equal build, batch.build
      assert_equal url, batch.url
      assert_equal name, batch.name
      assert_equal tags, batch.tags
      assert_equal results_path, batch.results_path
      assert_equal platforms, batch.platforms
    end

    describe "#register_batch" do
      it "adds the current build to the 'cross_browser_test_batches' set" do
        batch.register_batch

        assert_redis_command [:sadd, 'cross_browser_test_batches', build]
      end

      it "adds the initial options to the detail hash" do
        batch.register_batch

        assert_redis_command [:set, "cross_browser_test_batch:#{build}:detail", options.to_json]
      end
    end

    describe "#queue_all" do
      before do
        def batch.queue(platform); @queued_platforms ||= []; @queued_platforms << platform; end
        def batch.queued_platforms; @queued_platforms; end
      end

      it "calls queue for each platform" do
        def mock_results_worker.perform_in(*); end

        batch.queue_all

        assert_equal platforms, batch.queued_platforms
      end

      it "queues the results worker" do
        mock_results_worker.expect :perform_in, nil, [250, build]

        batch.queue_all

        mock_results_worker.verify
      end
    end

    describe "#queue" do
      let(:platform) { platforms.first }

      it "registers a job with the generated job_id" do
        def mock_worker.perform_async(*); 'hey hey boo boo'; end
        batch.queue(platform)

        assert_redis_command [:sadd, "cross_browser_test_batch:#{build}:pending", "hey hey boo boo"]
      end

      it "queues the job" do
        def mock_redis.sadd(*); end

        expected_options = { build: build,
                             url: url,
                             name: name,
                             tags: tags,
                             results_path: results_path}.merge(platform)

        mock_worker.expect :perform_async, nil, [expected_options]

        batch.queue(platform)

        mock_worker.verify
      end
    end
  end
end
