require 'spec_helper'

module EmberSecureBuilder
  describe AssetBuildingWorker do
    let(:fake_repo) { 'blahblah' }
    let(:fake_pr_number) { '3516' }
    let(:perform_cross_browser_tests) { 'true' }

    before do
      def AssetBuilder.publish_pull_request(*args); args; end
    end

    it "should delegate to AssetBuilder.publish" do
      result = AssetBuildingWorker.new.perform(fake_repo, fake_pr_number, perform_cross_browser_tests)

      expected = [fake_repo, fake_pr_number, perform_cross_browser_tests]

      assert_equal expected, result
    end
  end
end
