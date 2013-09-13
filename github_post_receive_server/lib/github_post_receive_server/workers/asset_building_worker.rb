module GithubPostReceiveServer
  class AssetBuildingWorker
    include Sidekiq::Worker

    def perform(repository, branch)
      puts "Doing something for the #{branch} branch of #{repository}."
    end
  end
end
