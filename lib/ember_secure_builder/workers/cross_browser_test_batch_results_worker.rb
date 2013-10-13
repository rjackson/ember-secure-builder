require 'sidekiq'

module EmberSecureBuilder
  class CrossBrowserTestBatchResultsWorker
    include Sidekiq::Worker

    def perform(build, times_requeued = 0)
      batch_results = CrossBrowserTestBatchResults.upload! build

      if batch_results.completed?
      elsif times_requeued < 150
        CrossBrowserTestBatchResultsWorker.perform_in 300, build, times_requeued + 1
      end
    end
  end
end
