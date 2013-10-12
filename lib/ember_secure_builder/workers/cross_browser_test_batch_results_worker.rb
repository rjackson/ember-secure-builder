require 'sidekiq'

module EmberSecureBuilder
  class SauceLabsWorker
    include Sidekiq::Worker

    sidekiq_options backtrace: true

    def perform(build)
      CrossBrowserTestBatchResults.upload!(build)
    end
  end
end
