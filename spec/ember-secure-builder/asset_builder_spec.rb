require 'spec_helper'

module EmberSecureBuilder
  describe AssetBuilder do
    let(:suspect_branch) { 'master' }
    let(:suspect_repo_path) { 'spec/support/suspect_repo_1' }

    let(:builder) { AssetBuilder.new(suspect_repo_path, suspect_branch) }

    after do
      builder.cleanup
    end

    describe 'initialize' do
      it "accepts the suspect repo and branch" do
        builder = AssetBuilder.new('blah blah', 'foo bar branch')

        assert_equal 'blah blah', builder.suspect_repo
        assert_equal 'foo bar branch', builder.suspect_branch
      end

      it "defaults debug to true" do
        assert builder.debug, 'debug is not true'
      end
    end

    describe "work_dir" do
      it "sets up an initial work directory" do
        assert builder.work_dir, 'work_dir is populated'
      end

      it "allows a work_dir to be specified" do
        builder = AssetBuilder.new(suspect_repo_path, suspect_branch, work_dir: 'some/tmp/path')

        assert_equal 'some/tmp/path', builder.work_dir
      end
    end

    describe "cleanup" do
      before do
        assert File.directory? builder.work_dir
      end

      it "cleans up after itself" do
        builder.cleanup
      end

      it "can be called more than once" do
        builder.cleanup
        builder.cleanup
        builder.cleanup
      end

      after do
        refute File.directory? builder.work_dir
      end
    end

    describe 'clone_suspect_repo' do
      it "exists" do
        assert_respond_to builder, :clone_suspect_repo
      end

      it "clones the suspect repo locally" do
        builder = AssetBuilder.new('blah blah', 'foo bar branch')
      end
    end
    it "checks out the correct branch of suspect repo"
    it "clones the good repo locally"
    it "copies the suspect repos packages/ dir into good repo"
    it "generates the correct dist files"
    it "publishes the dist files to S3"
  end
end
