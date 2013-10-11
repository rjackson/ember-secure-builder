require 'spec_helper'

module EmberSecureBuilder
  describe SauceLabsWorker do
    let(:worker) { SauceLabsWorker }

    before do
      worker.jobs.clear
    end
  end
end

