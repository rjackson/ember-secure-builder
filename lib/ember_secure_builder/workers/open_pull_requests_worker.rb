require 'sidekiq'
require 'sidekiq-cron'

module EmberSecureBuilder
  class OpenPullRequestsWorker
    include Sidekiq::Worker

    sidekiq_options backtrace: true

    def perform
      OpenPullRequests.run!
    end
  end
end

Sidekiq::Cron::Job.create( name: 'Open Pull Request - 5 Minutes', cron: '*/5 * * * *', klass: 'EmberSecureBuilder::OpenPullRequestsWorker')
