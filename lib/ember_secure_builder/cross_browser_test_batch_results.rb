module EmberSecureBuilder
  class CrossBrowserTestBatchResults
    include S3Uploader

    attr_accessor :build, :redis

    def self.upload!(build)
      batch_results = new(build)
      batch_results.save
      batch_results.cleanup if batch_results.completed?

      batch_results
    end

    def initialize(build, redis = Redis.new)
      self.build = build
      self.redis = redis
    end

    def details
      @details ||= JSON.parse(redis.get(key_prefix + ":detail"))
    end

    def completed?
      pending_jobs.empty?
    end

    def pending_jobs
      @pending_jobs ||= redis.smembers key_prefix + ":pending"
    end

    def completed_jobs
      @completed_jobs ||= redis.smembers key_prefix + ":completed"
    end

    def job_results
      @job_results ||= build_job_results
    end

    def save
      redis.set key_prefix + ":results", summary_results_hash.to_json

      if results_path
        upload(results_path + "/results.json", combined_results_hash.to_json)
      end
    end

    def results_path
      details['results_path']
    end

    def combined_results_hash
      details.merge('completed' => completed?, 'job_results' => job_results.values)
    end

    def summary_results_hash
      passed_jobs = job_results.values.select{|job| job['passed']}
      failed_jobs = job_results.values.reject{|job| job['passed']}

      passed = failed_jobs.empty?

      passed_browsers = passed_jobs.map{|job| [job['browser'], job['version']].join(' ') }
      failed_browsers = failed_jobs.map{|job| [job['browser'], job['version']].join(' ') }

      details.merge('passed?' => passed, 'passed' => passed_browsers, 'failed' => failed_browsers)
    end

    def cleanup
      redis.srem "cross_browser_test_batches", build
      redis.del key_prefix + ":detail"
      redis.del key_prefix + ":pending"

      completed_jobs.each do |job_id|
        redis.del key_prefix + ":#{job_id}:results"
      end

      redis.del key_prefix + ":completed"
    end

    private

    def build_job_results
      result_keys   = completed_jobs.map{|jid| key_prefix + ":#{jid}:results" }

      return {} if result_keys.empty?

      result_values = redis.mget *result_keys
      parsed_values = result_values.map{|v| JSON.parse(v) }

      Hash[completed_jobs.zip parsed_values]
    end

    def key_prefix
      "cross_browser_test_batch:#{build}"
    end
  end
end
