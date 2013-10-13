require 'sidekiq'
require 'sidekiq-cron'

module EmberSecureBuilder
  class OpenPullRequestsWorker
    include Sidekiq::Worker

    sidekiq_options backtrace: true

    def perform
      OpenPullRequests.run!
    rescue Octokit::TooManyRequests
      # stop the default sidekiq retry cycle if we have
      # hit the rate limit
    end
  end
end

unless ENV['RACK_ENV'] == 'test'
  Sidekiq::Cron::Job.create( name: 'Open Pull Request - 60 Minutes', cron: '0 * * * *', klass: 'EmberSecureBuilder::OpenPullRequestsWorker')
end
