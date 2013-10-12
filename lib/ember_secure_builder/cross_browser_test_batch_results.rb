module EmberSecureBuilder
  class CrossBrowserTestBatchResults
    attr_accessor :build, :redis

    def self.upload!(build)
      new(build).upload_results
    end

    def initialize(build, redis = Redis.new)
      self.build = build
      self.redis = redis
    end

    def details
      @details ||= JSON.parse(redis.get("cross_browser_test_batch:#{build}:detail"))
    end

    def completed?
      pending_jobs.empty?
    end

    def pending_jobs
      @pending_jobs ||= redis.smembers "cross_browser_test_batch:#{build}:pending"
    end

    def completed_jobs
      @completed_jobs ||= redis.smembers "cross_browser_test_batch:#{build}:completed"
    end

    def job_results
      result_keys   = completed_jobs.map{|jid| "cross_browser_test_batch:#{build}:#{jid}:results" }
      result_values = redis.mget *result_keys
      parsed_values = result_values.map{|v| JSON.parse(v) }

      Hash[completed_jobs.zip parsed_values]
    end

    def upload_results(options = {})
      return unless results_path

      bucket = options.fetch(:bucket) { build_s3_bucket }

      destination_path = results_path + "/results.json"

      obj = bucket.objects[destination_path.gsub(' ', '_').downcase]
      obj.write(combined_results_hash.to_json, {:content_type => 'application/json'})
    end

    def results_path
      details['results_path']
    end

    def combined_results_hash
      details.merge('completed' => completed?, 'job_results' => job_results.values)
    end

    private

    def build_s3_bucket
      s3 = AWS::S3.new(:access_key_id => ENV['S3_ACCESS_KEY_ID'],
                       :secret_access_key => ENV['S3_SECRET_ACCESS_KEY'])

      s3.buckets[ENV['S3_BUCKET_NAME']]
    end
  end
end
