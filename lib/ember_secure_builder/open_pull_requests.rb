require 'octokit'

module EmberSecureBuilder
  class OpenPullRequests
    include S3Uploader

    attr_accessor :repo, :redis

    def self.run!
      new('emberjs/ember.js').save('ember/pull_requests.json')
      new('emberjs/data').save('ember-data/pull_requests.json')
    end

    def initialize(repo, options = {})
      self.repo  = repo
      self.redis = options.fetch(:redis) { Redis.new }

      @queue_missing_worker = options.fetch(:queue_missing_worker, AssetBuildingWorker)
    end

    def pull_requests
      @pull_requests ||= fetch
    end

    def summary
      pull_requests.map{|pr| pull_request_details(pr) }
    end

    def pull_request_details(pull_request)
      {
        number: pull_request['number'],
        user: pull_request['user']['login'],
        title: pull_request['title'],
        build: pull_request['head']['sha'],
      }.merge(pull_request_test_results(pull_request))
    end

    def save(path)
      upload(path, summary.to_json)
    end

    private

    def pull_request_test_results(pull_request)
      sha = pull_request['head']['sha']

      if results = redis.get("cross_browser_test_batch:#{sha}:results")
        JSON.parse(results)
      else
        queue_asset_build pull_request

        {}
      end
    end

    def queue_asset_build(pull_request)
      sha = pull_request['head']['sha']

      return unless @queue_missing_worker
      return unless redis.get("cross_browser_test_batch:#{sha}:detail").nil?
      return unless pull_request['updated_at'] > Time.now - 60 * 60 * 24 * 14

      pull_request_number = pull_request['number']

      @queue_missing_worker.perform_async(repo, pull_request_number, true)
    end

    def fetch
      Octokit.pull_requests repo
    end
  end
end
