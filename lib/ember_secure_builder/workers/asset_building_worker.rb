require 'sidekiq'

module EmberSecureBuilder
  class AssetBuildingWorker
    include Sidekiq::Worker

    def perform(repository, branch)
      AssetBuilder.publish(suspect_repo: repository, suspect_branch: branch)
    end
  end
end
