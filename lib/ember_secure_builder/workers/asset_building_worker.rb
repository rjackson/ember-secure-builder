require 'sidekiq'

module EmberSecureBuilder
  class AssetBuildingWorker
    include Sidekiq::Worker

    def perform(repository, branch)
      AssetBuilder.publish(repository, branch)
    end
  end
end
