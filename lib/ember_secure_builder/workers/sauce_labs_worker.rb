require 'securerandom'
require 'sidekiq'

module EmberSecureBuilder
  class SauceLabsWorker
    include Sidekiq::Worker

    sidekiq_options backtrace: true

    SAUCE_LABS_POOL = ConnectionPool.new(:size => 8) { "Must pass a block here, even though we don't care..." }

    def perform(options)
      SAUCE_LABS_POOL.with do
        SauceLabsWebdriverJob.run!(options)
      end
    end
  end
end
