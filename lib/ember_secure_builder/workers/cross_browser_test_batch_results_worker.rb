require 'sidekiq'

module EmberSecureBuilder
  class CrossBrowserTestBatchResultsWorker
    class IncompleteResultsError < StandardError; end

    include Sidekiq::Worker

    def perform(build)
      batch_results = CrossBrowserTestBatchResults.new build
      batch_results.upload_results

      unless batch_results.completed?
        throw IncompleteResultsError, "Not finished yet. #{batch_results.pending_jobs.length} jobs still pending."
      end
    end
  end
end
