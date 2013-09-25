require 'spec_helper'

module EmberSecureBuilder
  describe AssetBuilder do
    let(:suspect_branch) { 'master' }
    let(:suspect_repo_path) { Pathname.new 'spec/support/test_repos/suspect_repo_1' }
    let(:suspect_repo_url) { "file://#{suspect_repo_path.realpath}" }

    let(:good_branch) { 'master' }
    let(:good_repo_path) { Pathname.new 'spec/support/test_repos/good_repo' }
    let(:good_repo_url) { "file://#{good_repo_path.realpath}" }

    let(:builder) do
      AssetBuilder.new(suspect_repo_url, suspect_branch,
                       good_repo: good_repo_url, good_branch: good_branch,
                       debug: false)
    end

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
        builder = AssetBuilder.new('blah blah', 'foo bar branch')

        assert builder.debug, 'debug is not true'
      end

      it "defaults the good_repo to emberjs/ember.js" do
        builder = AssetBuilder.new('blah blah', 'foo bar branch')

        assert_equal 'git@github.com:emberjs/ember.js.git', builder.good_repo
      end

      it "defaults the good_batch to master" do
        builder = AssetBuilder.new('blah blah', 'foo bar branch')

        assert_equal 'master', builder.good_branch
      end
    end

    describe "work_dir" do
      it "sets up an initial work directory" do
        assert builder.work_dir, 'work_dir is populated'
      end

      it "allows a work_dir to be specified" do
        builder = AssetBuilder.new(suspect_repo_url, suspect_branch, work_dir: 'some/tmp/path')

        assert_equal 'some/tmp/path', builder.work_dir.to_s
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

    describe 'clone_repos' do
      before do
        builder.clone_repos
      end

      it "clones the suspect repo locally" do
        assert File.directory?("#{builder.work_dir}/suspect/packages/some-random-package")
      end

      it "clones the good repo locally" do
        assert File.directory?("#{builder.work_dir}/good/packages/some-good-package")
      end
    end

    describe "copy_suspect_packages" do
      it "copies the packages/ dir from suspect into good" do
        builder.copy_suspect_packages

        assert File.directory?("#{builder.work_dir}/good/packages/some-random-package")
      end

      it "removes any packages from good" do
        builder.copy_suspect_packages

        refute File.directory?("#{builder.work_dir}/good/packages/some-good-package")
      end

      it "does not copy anything from suspect other than packages/" do
        builder.copy_suspect_packages

        refute File.directory?("#{builder.work_dir}/good/this_should_NOT_be_copied")
      end
    end

    describe 'build' do
      before do
        builder.clone_repos

        def builder.system(command)
          @commands ||= []
          @commands << {command: command, env: ENV, cwd: Dir.getwd}
        end
        def builder.system_commands_called; @commands; end
      end

      it "calls rake dist from the good repo dir" do
        builder.build

        command = builder.system_commands_called.first

        assert_equal command[:command], 'rake dist'
        assert_equal command[:cwd], builder.work_dir.join('good').realpath.to_s
      end
    end

    describe 'publish' do
      it "publishes the dist files to S3" do

      end
    end
  end
end
