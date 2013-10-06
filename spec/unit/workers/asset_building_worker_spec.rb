require 'spec_helper'

module EmberSecureBuilder
  describe AssetBuildingWorker do
    let(:fake_repo) { 'blahblah' }
    let(:fake_branch) { 'master' }

    before do
      def AssetBuilder.publish(options); options; end
    end

    it "should delegate to AssetBuilder.publish" do
      result = AssetBuildingWorker.new.perform(fake_repo, fake_branch)

      assert_equal({suspect_repo: fake_repo, suspect_branch: fake_branch}, result)
    end
  end
end
