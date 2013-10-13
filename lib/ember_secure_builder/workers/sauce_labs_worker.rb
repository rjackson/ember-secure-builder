require 'securerandom'
require 'sidekiq'

module EmberSecureBuilder
  class SauceLabsWorker
    include Sidekiq::Worker

    sidekiq_options backtrace: true, :retry => 3, :queue => :sauce_labs

    SAUCE_LABS_POOL = ConnectionPool.new(:size => 8) { "Must pass a block here, even though we don't care..." }

    def perform(options, job_class = SauceLabsWebdriverJob)
      SAUCE_LABS_POOL.with do
        job_class.run!(options.merge(sidekiq_job_id: jid))
      end
    end
  end
end
