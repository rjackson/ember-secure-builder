require 'securerandom'
require 'spec_helper'

module EmberSecureBuilder
  describe SauceLabsWorker do
    let(:worker) { SauceLabsWorker.new }
    let(:jid)    { SecureRandom.urlsafe_base64 }
    let(:mock_job_class) { Minitest::Mock.new }

    before do
      SauceLabsWorker.jobs.clear
    end

    it "passes the current job id along to the job" do
      worker.jid = jid
      options = {some: 'random'}

      mock_job_class.expect :run!, nil, [options.merge(sidekiq_job_id: jid)]

      worker.perform(options, mock_job_class)

      mock_job_class.verify
    end
  end
end

