require 'spec_helper'

module EmberSecureBuilder
  describe CrossBrowserTestBatchResults do
    include TestSupport::RedisAssertion

    let(:build)   { SecureRandom.urlsafe_base64 }
    let(:results) { CrossBrowserTestBatchResults.new build, mock_redis}
    let(:mock_redis) { TestSupport::MockRedis.new }

    it "accepts a build id on initialize" do
      assert_equal build, results.build
    end

    it "accepts a redis connection on initialize" do
      CrossBrowserTestBatchResults.new build, mock_redis
    end

    describe "#details" do
      let(:detail_key) { "cross_browser_test_batch:#{build}:detail" }

      before do
        def mock_redis.get(*args); @get_params = args; '{"string": "blah blah"}'; end
        def mock_redis.get_params; @get_params; end
      end

      it "retrieves the batch details" do
        results.details

        assert_equal [detail_key], mock_redis.get_params
      end

      it "returns the batch details" do
        assert_equal({"string" => 'blah blah'}, results.details)
      end
    end

    describe "#completed?" do
      it "should be false if jobs are still pending" do
        def results.pending_jobs; ['something']; end

        refute results.completed?
      end

      it "should be true if no jobs are pending" do
        def results.pending_jobs; []; end

        assert results.completed?
      end
    end

    describe "#pending_jobs" do
      it "should lookup the members of the pending set" do
        results.pending_jobs

        expected = [:smembers, "cross_browser_test_batch:#{build}:pending"]

        assert_redis_command expected
      end

      it "returns the members of the pending set" do
        def mock_redis.smembers(*args); ['array','values']; end

        assert_equal ['array','values'], results.pending_jobs
      end
    end

    describe "#completed_jobs" do
      it "should lookup the members of the completed set" do
        results.completed_jobs

        expected = [:smembers, "cross_browser_test_batch:#{build}:completed"]

        assert_redis_command expected
      end

      it "returns the members of the completed set" do
        def mock_redis.smembers(*args); ['array','values']; end

        assert_equal ['array','values'], results.completed_jobs
      end
    end

    describe "#results" do
      let(:result_keys) { results.completed_jobs.map{|jid| "cross_browser_test_batch:#{build}:#{jid}:results" } }

      before do
        def results.completed_jobs; ['fred', 'alex','rob']; end
        def mock_redis.mget(*args); @mget_params = args; ['{"lname": "flinstone"}','{"lname": "navasardyan"}','{"lname": "jackson"}']; end
        def mock_redis.mget_params; @mget_params; end
      end

      it "reads the key for each completed job" do
        results.job_results

        assert_equal result_keys, mock_redis.mget_params
      end

      it "combines the results into a hash" do
        expected = {'fred' => {"lname" => 'flinstone'},
                    'alex' => {"lname" => 'navasardyan'},
                    'rob'  => {"lname" => 'jackson'}}

        assert_equal expected, results.job_results
      end
    end

    describe "#upload_results" do
      let(:fake_bucket)  { TestSupport::MockS3Bucket.new }
      let(:results_path) { 'fred/flinstone' }

      before do
        def results.build_s3_bucket
          @build_s3_bucket_called = true
          TestSupport::MockS3Bucket.new
        end

        def results.build_s3_bucket_called
          @build_s3_bucket_called
        end

        def results.combined_results_hash; 'random results'; end
        def results.results_path; 'fred/flinstone'; end
      end

      describe "when no results_path is specified" do
        before do
          def results.results_path; nil; end
        end

        it "doesn't add any files to the bucket" do
          results.upload_results(:bucket => fake_bucket)

          assert_equal 0, fake_bucket.objects.length
        end

        it "doesn't call build_s3_bucket" do
          results.upload_results

          refute results.build_s3_bucket_called
        end
      end

      it "calls build_s3_bucket if no bucket is provided" do
        results.upload_results

        assert results.build_s3_bucket_called
      end

      it "uses the bucket if provided" do
        results.upload_results(:bucket => fake_bucket)

        refute results.build_s3_bucket_called
      end

      it "uploads files" do
        results.upload_results(:bucket => fake_bucket)

        assert_equal 1, fake_bucket.objects.length
      end

      it "saves data from combined_results_hash" do
        results.upload_results(:bucket => fake_bucket)

        expected_dest = results_path + "/results.json"
        expected_dest = expected_dest.downcase.gsub(' ', '_')

        s3_object = fake_bucket.objects[expected_dest]

        assert_equal 'random results'.to_json, s3_object.source_path
      end
    end

    describe "#combined_results_hash" do

      it "return the batch details with final job results" do
        def results.completed?; false; end
        def results.details; {'foo' => 'bar'}; end
        def results.job_results; {'test1' => {'some' => 'test'}, 'test2' => {'results' => 'here'}}; end

        expected = {'completed' => false, 'foo' => 'bar',
                    'job_results' => [{'some' => 'test'},
                                      {'results' => 'here'}] }

        assert_equal expected, results.combined_results_hash
      end
    end

    describe "#cleanup" do
      let(:key_prefix) { "cross_browser_test_batch:#{build}" }

      before do
        def results.completed_jobs; ['foo','bar','baz','biff']; end

        results.cleanup
      end

      it "should delete the batches entry in the batch listing" do
        assert_redis_command [:srem, "cross_browser_test_batches", build]
      end

      it "should delete the batch details" do
        assert_redis_command [:del, key_prefix + ":detail"]
      end

      it "should delete the pending jobs set" do
        assert_redis_command [:del, key_prefix + ":pending"]
      end

      it "should delete the results for each job" do
        results.completed_jobs.each do |job_id|
          assert_redis_command [:del, key_prefix + ":#{job_id}:results"]
        end
      end

      it "should delete the completed jobs set" do
        assert_redis_command [:del, key_prefix + ":completed"]
      end
    end

  end
end

