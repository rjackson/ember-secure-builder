require 'spec_helper'

module EmberSecureBuilder
  describe CrossBrowserTestBatchResults do
    include TestSupport::RedisAssertion

    let(:build)   { SecureRandom.urlsafe_base64 }
    let(:results) { CrossBrowserTestBatchResults.new build, mock_redis}
    let(:mock_redis) { TestSupport::MockRedis.new }

    let(:key_prefix) { "cross_browser_test_batch:#{build}" }

    it "accepts a build id on initialize" do
      assert_equal build, results.build
    end

    it "accepts a redis connection on initialize" do
      CrossBrowserTestBatchResults.new build, mock_redis
    end

    describe "#details" do
      let(:detail_key) { "#{key_prefix}:detail" }

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

        expected = [:smembers, "#{key_prefix}:pending"]

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

        expected = [:smembers, "#{key_prefix}:completed"]

        assert_redis_command expected
      end

      it "returns the members of the completed set" do
        def mock_redis.smembers(*args); ['array','values']; end

        assert_equal ['array','values'], results.completed_jobs
      end
    end

    describe "#results" do
      let(:result_keys) { results.completed_jobs.map{|jid| "#{key_prefix}:#{jid}:results" } }

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

    describe "#failed_jobs" do

    end

    describe "#save" do
      before do
        def results.upload(*args); @upload_args = args; @upload_called = true; end
        def results.upload_called; @upload_called; end
        def results.upload_args; @upload_args; end

        def results.combined_results_hash; 'detailed results'; end
        def results.summary_results_hash; 'summary results'; end

        def results.results_path; 'foo/bar'; end
      end

      it "calls upload" do
        results.save

        assert_equal ['foo/bar/results.json', '"detailed results"'], results.upload_args
      end

      it "doesn't call upload if results_path is nil" do
        def results.results_path; nil; end

        results.save

        refute results.upload_called
      end

      it "writes the combined results to the batch's results key" do
        results.save

        assert_redis_command [:set, key_prefix + ":results", results.summary_results_hash.to_json]
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

    describe "#summary_results_hash" do
      before do
        def results.details; {'build' => 'SOME SHA'}; end
      end

      describe "with failed jobs" do
        before do
          def results.job_results
            {'fred' => {'passed' => false, 'browser' => 'opera', 'version' => '12'},
             'barney' => {'passed' => true, 'browser' => 'chrome', 'version' => ''},
             'wilma' => {'passed' => true, 'browser' => 'ie', 'version' => '9'},
             'betty' => {'passed' => false, 'browser' => 'blah', 'version' => '99'}}
          end
        end

        it "should indicate failure if a job didn't pass" do
          refute results.summary_results_hash['passed?']
        end

        it "should include a list of failed browsers" do
          expected = ['opera 12', 'blah 99']

          assert_equal expected, results.summary_results_hash['failed']
        end

        it "should include a list of passed browsers" do
          expected = ['chrome ', 'ie 9']

          assert_equal expected, results.summary_results_hash['passed']
        end

        it "includes the batch details" do
          assert_equal 'SOME SHA', results.summary_results_hash['build']
        end
      end

      describe "without failed jobs" do
        before do
          def results.job_results
            {'fred' => {'passed' => true, 'browser' => 'opera', 'version' => '12'},
             'barney' => {'passed' => true, 'browser' => 'chrome', 'version' => ''},
             'wilma' => {'passed' => true, 'browser' => 'ie', 'version' => '9'},
             'betty' => {'passed' => true, 'browser' => 'blah', 'version' => '99'}}
          end
        end

        it "should indicate failure if a job didn't pass" do
          assert results.summary_results_hash['passed?']
        end

        it "should include an empty list of failed browsers" do
          expected = []

          assert_equal expected, results.summary_results_hash['failed']
        end

        it "should include a list of passed browsers" do
          expected = ["opera 12", "chrome ", "ie 9", "blah 99"]

          assert_equal expected, results.summary_results_hash['passed']
        end

        it "includes the batch details" do
          assert_equal 'SOME SHA', results.summary_results_hash['build']
        end
      end
    end

    describe "#cleanup" do

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

