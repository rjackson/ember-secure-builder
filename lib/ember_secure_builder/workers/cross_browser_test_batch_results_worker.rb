require 'sidekiq'

module EmberSecureBuilder
  class CrossBrowserTestBatchResultsWorker
    include Sidekiq::Worker

    def perform(build, times_requeued = 0)
      batch_results = CrossBrowserTestBatchResults.upload! build

      if batch_results.completed?
      elsif times_requeued < 30
        CrossBrowserTestBatchResultsWorker.perform_in 120, build, times_requeued + 1
      end
    end
  end
end
