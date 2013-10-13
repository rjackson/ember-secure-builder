require 'spec_helper'

module EmberSecureBuilder
  describe OpenPullRequests do
    include TestSupport::RedisAssertion

    let(:pull_requests) { OpenPullRequests.new repo, redis: mock_redis }
    let(:mock_redis) { TestSupport::MockRedis.new }
    let(:mock_worker) { Minitest::Mock.new }

    let(:repo) { 'emberjs/ember.js' }

    it "should make passed in repo available" do
      assert_equal repo, pull_requests.repo
    end

    describe "#pull_requests" do
      it "should populate pull_requests" do
        VCR.use_cassette('open_pull_requests') do
          assert pull_requests.pull_requests
        end
      end
    end

    describe "#pull_request_details" do
      let(:build) { 'SOME SHA GOES HERE' }
      let(:input) do
        {'number' => 12312,
         'user' => { 'login' => 'rjackson' },
         'title' => 'Whoa, awesome!',
         'head' => {'sha' => build},
         'updated_at' => Time.now - 60 * 60 * 24 * 4}
      end

      before do
        def mock_redis.get(key); @get_key = key; '{"boo": "yaah"}'; end
        def mock_redis.get_key; @get_key; end
      end

      it "should reformat the input data" do
        output = pull_requests.pull_request_details(input)

        assert_equal 12312, output[:number]
        assert_equal 'rjackson', output[:user]
        assert_equal 'Whoa, awesome!', output[:title]
        assert_equal 'SOME SHA GOES HERE', output[:build]
      end

      it "looks up the builds results" do
        output = pull_requests.pull_request_details(input)

        assert_equal "cross_browser_test_batch:#{build}:results", mock_redis.get_key
      end

      it "includes any results from pull_request_test_results" do
        output = pull_requests.pull_request_details(input)

        assert_equal 'yaah', output['boo']
      end

      it "doesn't blow up if sha results aren't found" do
        def mock_redis.get(key); nil; end
        output = pull_requests.pull_request_details(input)

        assert_equal 'rjackson', output[:user]
      end

      it "queues asset builder if queue_missing is passed on init" do
        pull_requests = OpenPullRequests.new repo, redis: mock_redis, queue_missing_worker: mock_worker

        def mock_redis.get(key); nil; end
        mock_worker.expect :perform_async, nil, [repo, 12312, true]

        output = pull_requests.pull_request_details(input)

        mock_worker.verify
      end
    end

    describe "#summary" do
      it "calls pull_request_details for each pull_request" do
        def pull_requests.pull_requests; ['foo','bar']; end
        def pull_requests.pull_request_details(pr); pr; end

        assert_equal ['foo','bar'], pull_requests.summary
      end
    end
  end
end
