require 'sidekiq'

module EmberSecureBuilder
  class AssetBuildingWorker
    include Sidekiq::Worker

    sidekiq_options backtrace: true

    def perform(repository, pull_request_number, perform_cross_browser_tests)
      AssetBuilder.publish_pull_request(repository, pull_request_number, perform_cross_browser_tests)
    end
  end
end
