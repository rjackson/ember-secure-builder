require 'securerandom'

module EmberSecureBuilder
  class CrossBrowserTestBatch
    attr_accessor :build, :url, :name, :tags,
                  :results_path,
                  :platforms, :redis, :worker_class,
                  :initial_options

    def self.redis
      @redis ||= Redis.new
    end

    def self.queue(options)
      batch = new(options)
      batch.register_batch
      batch.queue_all
    end

    def initialize(options)
      self.initial_options = options

      self.build        = options.fetch(:build)
      self.url          = options.fetch(:url)
      self.name         = options.fetch(:name, '')
      self.tags         = options.fetch(:tags) { [] }
      self.results_path = options.fetch(:results_path, nil)

      self.redis        = options.fetch(:redis)        { self.class.redis }
      self.platforms    = options.fetch(:platforms)    { SauceLabsWebdriverJob.default_platforms }
      self.worker_class = options.fetch(:worker_class) { SauceLabsWorker }
    end

    def register_batch
      redis.sadd 'cross_browser_test_batch', build
    end

    def queue_all
      platforms.map{|hash| queue(hash) }
    end

    def queue(platform)
      job_id = generate_job_id

      redis.sadd "cross_browser_test_batch:#{build}", job_id

      options = job_options.merge(platform).merge(job_id: job_id)
      worker_class.perform_async options

      job_id
    end

    private

    def job_options
      { build: build,
        url: url,
        name: name,
        tags: tags,
        results_path: results_path}
    end

    def generate_job_id
      SecureRandom.urlsafe_base64
    end
  end
end
