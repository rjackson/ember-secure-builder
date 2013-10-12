require 'sidekiq'

module EmberSecureBuilder
  class CrossBrowserTestBatchResultsWorker
    include Sidekiq::Worker

    def perform(build, times_requeued = 0)
      batch_results = CrossBrowserTestBatchResults.new build
      batch_results.upload_results

      if batch_results.completed?
        #batch_results.cleanup
      else if times_requeued < 30
        CrossBrowserTestBatchResultsWorker.perform_in 120, build, times_requeued + 1
      end
    end
  end
end
