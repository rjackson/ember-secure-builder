require 'spec_helper'

require_relative '../support/mock_s3_classes'


module EmberSecureBuilder
  describe AssetBuilder do
    let(:project) { 'emberjs/ember.js' }
    let(:suspect_branch) { 'master' }
    let(:suspect_repo_path) { Pathname.new 'spec/support/test_repos/suspect_repo_1' }
    let(:suspect_repo_url) { "file://#{suspect_repo_path.realpath}" }

    let(:good_branch) { 'master' }
    let(:good_repo_path) { Pathname.new 'spec/support/test_repos/good_repo' }
    let(:good_repo_url) { "file://#{good_repo_path.realpath}" }
    let(:mock_batch_class) { Minitest::Mock.new  }

    let(:builder) do
      AssetBuilder.new(project, suspect_repo: suspect_repo_url,
                       suspect_branch: suspect_branch,
                       good_repo: good_repo_url, good_branch: good_branch,
                       debug: false, cross_browser_test_batch: mock_batch_class)
    end

    after do
      builder.cleanup
    end

    describe 'initialize' do
      it "accepts the suspect repo and branch" do
        builder = AssetBuilder.new(project, suspect_repo: 'blah blah', suspect_branch: 'foo bar branch')

        assert_equal 'blah blah', builder.suspect_repo
        assert_equal 'foo bar branch', builder.suspect_branch
      end

      it "defaults debug to true" do
        builder = AssetBuilder.new(project, suspect_repo: 'blah blah', suspect_branch: 'foo bar branch')

        assert builder.debug, 'debug is not true'
      end

      it "defaults the good_repo to emberjs/ember.js" do
        builder = AssetBuilder.new(project, suspect_repo: 'blah blah', suspect_branch: 'foo bar branch')

        assert_equal 'https://github.com/rjackson/ember.js', builder.good_repo
      end

      it "defaults the good_batch to master" do
        builder = AssetBuilder.new(project, suspect_repo: 'blah blah', suspect_branch: 'foo bar branch')

        assert_equal 'static_test_generator', builder.good_branch
      end
    end

    describe "work_dir" do
      it "sets up an initial work directory" do
        assert builder.work_dir, 'work_dir is populated'
      end

      it "allows a work_dir to be specified" do
        builder = AssetBuilder.new(project, suspect_repo: suspect_repo_url,
                                   suspect_branch: suspect_branch,
                                   work_dir: 'some/tmp/path')

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

    describe '#load_from_pull_request' do
      let(:builder) { AssetBuilder.new(project, debug: false) }
      let(:main_repo) { 'emberjs/ember.js' }
      let(:pr_number) { 3481 }

      before do
        VCR.use_cassette 'load_suspect_from_pull_request' do
          builder.load_from_pull_request(main_repo, pr_number)
        end
      end

      it "can load the suspect_repo" do
        assert_equal builder.suspect_repo, 'https://github.com/rjackson/ember.js'
      end

      it "can load the suspect branch" do
        assert_equal builder.suspect_branch, 'update_ember-dev'
      end

      it "sets the pull_request_number" do
        assert_equal builder.pull_request_number, pr_number
      end
    end

    describe '#last_suspect_repo_commit' do
      let(:suspect_branch)   { 'master' }
      let(:suspect_repo_url) { "https://github.com/emberjs/ember.js" }

      it "returns the latest SHA for the given branch" do
        VCR.use_cassette 'last_suspect_repo_commit' do
          assert_equal '5f58c297941a5e649a41383aa75c330ef0f1f7b7', builder.last_suspect_repo_commit
        end
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

      it "raises an error if clone_repos returns false" do
        def builder.clone_repos; false; end

        assert_raises(AssetBuilder::CloneRepoError) { builder.copy_suspect_packages }
      end
    end

    describe 'build' do
      before do
        def builder.clone_repos; @clone_repos_called = true; end
        def builder.copy_suspect_packages; @copy_suspect_packages_called = true; end

        def builder.clone_repos_called; @clone_repos_called; end
        def builder.copy_suspect_packages_called; @copy_suspect_packages_called; end

        def builder.system(command)
          @commands ||= []
          @commands << {command: command, env: ENV, cwd: Dir.getwd}
        end
        def builder.system_commands_called; @commands; end
      end

      it "calls clone_repo" do
        builder.build

        assert builder.clone_repos_called
      end

      it "calls copy_suspect_packages" do
        builder.build

        assert builder.copy_suspect_packages
      end

      it "calls rake dist from the good repo dir" do
        builder.build

        command = builder.system_commands_called.first
        expected_command = "cd #{builder.work_dir.join('good')} && bundle install && bundle exec rake dist ember:generate_static_test_site"

        assert_equal expected_command, command[:command]
      end
    end

    describe 'upload' do
      let(:fake_bucket) { TestSupport::MockS3Bucket.new }

      before do
        def builder.build_s3_bucket
          @build_s3_bucket_called = true
          TestSupport::MockS3Bucket.new
        end

        def builder.build_s3_bucket_called
          @build_s3_bucket_called
        end
      end

      it "calls build_s3_bucket if no bucket is provided" do
        builder.upload

        assert builder.build_s3_bucket_called
      end

      it "uses the bucket if provided" do
        builder.upload(:bucket => fake_bucket)

        refute builder.build_s3_bucket_called
      end

      it "uploads files" do
        builder.upload(:bucket => fake_bucket)

        assert_equal 4, fake_bucket.objects.length
      end

      describe "sets the correct source and destination paths" do
        before do
          builder.upload(:bucket => fake_bucket)

          files.each do |file|
            expected_dest = builder.asset_destination_path + "/#{file}"
            expected_src  = builder.asset_source_path.join(file)

            s3_object = fake_bucket.objects[expected_dest]

            assert_equal expected_src, s3_object.source_path
          end
        end

        describe "for emberjs/ember.js" do
          let(:project) { 'emberjs/ember.js' }
          let(:files) { %w{ember.js ember-spade.js ember-tests.js ember-tests.html} }

          it "works" do
            assert_equal files.length, fake_bucket.objects.length
          end
        end

        describe "for emberjs/data" do
          let(:project) { 'emberjs/data' }
          let(:files) { %w{ember-spade.js ember-data-tests.js ember-data-tests.html} }

          it "works" do
            assert_equal files.length, fake_bucket.objects.length
          end
        end
      end

      it "sets the correct object options" do
        builder.upload(:bucket => fake_bucket)

        s3_object = fake_bucket.objects.values.first
        assert_equal({content_type: 'text/javascript'}, s3_object.options)
      end
    end

    describe "#asset_source_path" do
      it "should return the provided asset_source_path option" do
        builder = AssetBuilder.new(project, suspect_repo: suspect_repo_url, suspect_branch: suspect_branch,
                                   good_repo: good_repo_url, good_branch: good_branch,
                                   debug: false, :asset_source_path => 'foo/bar/path')

        assert_equal 'foo/bar/path', builder.asset_source_path
      end

      it "should return dist/ember.js in the good repo path by default" do
        assert_equal builder.work_dir.join('good/dist'), builder.asset_source_path
      end
    end

    describe "#queue_cross_browser_tests" do
      let(:mock_worker) { Minitest::Mock.new }

      before do
        def builder.last_suspect_repo_commit; 'some sha'; end
        def builder.test_url; 'some url'; end
        def builder.project_name; 'Whoo hoo'; end
        def builder.project_prefix; 'whoo-hoo'; end
      end

      it "queues tests for the default platforms" do
        expected_argument = {
          :url   => 'some url',
          :name  => 'Whoo hoo',
          :build => 'some sha',
          :tags  => ['whoo-hoo', builder.suspect_branch],
          :results_path => builder.asset_destination_path,
          :repo_url => suspect_repo_url,
          :commit_url => suspect_repo_url + "/commit/some sha"
        }

        mock_worker.expect :queue, nil, [expected_argument]

        builder.queue_cross_browser_tests mock_worker

        mock_worker.verify
      end
    end
  end
end
