require 'spec_helper'

module EmberSecureBuilder
  describe AssetBuildingWorker do
    let(:fake_repo) { 'blahblah' }
    let(:fake_pr_number) { '3516' }
    let(:perform_cross_browser_tests) { 'true' }

    before do
      def AssetBuilder.publish_pull_request(options); options; end
    end

    it "should delegate to AssetBuilder.publish" do
      result = AssetBuildingWorker.new.perform(fake_repo, fake_pr_number, perform_cross_browser_tests)

      expected = {repository: fake_repo,
                  pull_request_number: fake_pr_number,
                  perform_cross_browser_tests: perform_cross_browser_tests}

      assert_equal expected, result
    end
  end
end
