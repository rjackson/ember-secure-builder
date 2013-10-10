require 'sidekiq'

module EmberSecureBuilder
  class SauceLabsWorker
    include Sidekiq::Worker

    sidekiq_options backtrace: true

    SAUCE_LABS_POOL = ConnectionPool.new(:size => 8) { "Must pass a block here, even though we don't care..." }

    def self.queue_cross_browser_tests(options)
      platforms    = options.fetch(:platforms) { SauceLabsWebdriverJob.default_platforms }
      worker_class = options.fetch(:worker_class) { self }
      test_options = options.fetch(:test_options)

      platforms.map do |platform|
        worker_class.perform_async(platform.merge(test_options))
      end
    end

    def perform(options)
      SAUCE_LABS_POOL.with do
        SauceLabsWebdriverJob.run!(options)
      end
    end
  end
end
