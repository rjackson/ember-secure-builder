require 'json'
require 'securerandom'
require 'spec_helper'

module EmberSecureBuilder
  describe SauceLabsWebdriverJob do
    include WebMock::API

    let(:mock_capabilities_class) { Minitest::Mock.new }
    let(:mock_driver_class)       { Minitest::Mock.new }

    let(:sauce) { SauceLabsWebdriverJob.new(options) }

    let(:options) do
      {username: username,
       access_key: access_key,
       platform: platform,
       browser: browser,
       version: version,
       url: url,
       name: job_name,
       build: build,
       tags: tags,
       capabilities_class: mock_capabilities_class,
       driver_class: mock_driver_class,
       results_path: results_path}
    end

    let(:username)    { SecureRandom.urlsafe_base64 }
    let(:access_key)  { SecureRandom.urlsafe_base64 }
    let(:url)         { "https://blahblah.com/something/#{SecureRandom.urlsafe_base64}" }
    let(:job_name)    { SecureRandom.urlsafe_base64 }

    let(:platform) { "Windows 7" }
    let(:browser)  { "internet_explorer" }
    let(:version)  { "10" }
    let(:build)    { SecureRandom.urlsafe_base64 }
    let(:tags)     { [] }
    let(:results_path) { nil }

    describe "#initialize" do
      it "converts the hash's keys to sym before accessing." do
        sauce = SauceLabsWebdriverJob.new "url" => 'something random'

        assert_equal 'something random', sauce.url
      end
    end

    describe "#username" do
      it "accepts the SauceLabsWebdriverJob username on init" do
        sauce = SauceLabsWebdriverJob.new(username: 'blah')

        assert_equal 'blah', sauce.username
      end

      it "pulls from ENV if not specified" do
        sauce = SauceLabsWebdriverJob.new env: {'SAUCE_LABS_USERNAME' => 'blah'}

        assert_equal 'blah', sauce.username
      end
    end

    describe "#access_key" do
      it "accepts the SauceLabsWebdriverJob access_key on init" do
        sauce = SauceLabsWebdriverJob.new(access_key: 'blah')

        assert_equal 'blah', sauce.access_key
      end

      it "pulls from ENV if not specified" do
        sauce = SauceLabsWebdriverJob.new env: {'SAUCE_LABS_ACCESS_KEY' => 'blah'}

        assert_equal 'blah', sauce.access_key
      end
    end

    describe "#name" do
      it "saves the name when provided on init" do
        sauce = SauceLabsWebdriverJob.new(name: 'blah')

        assert_equal 'blah', sauce.name
      end

      it "uses last commit SHA if not specified" do
        sauce = SauceLabsWebdriverJob.new

        assert_equal `git rev-list --max-count=1 HEAD`, sauce.name
      end
    end

    describe "#tags" do
      it "saves the tags when provided on init" do
        tags = ['fred', 'barney']
        sauce = SauceLabsWebdriverJob.new(tags: tags)

        assert_equal tags, sauce.tags
      end

      it "uses empty array if not specified" do
        sauce = SauceLabsWebdriverJob.new

        assert_equal [], sauce.tags
      end
    end

    describe "#capabilities" do
      it "should create a browser specific capabilities instance" do
        mock_capabilities_class.expect browser, 'called mock capabilities',
          [{:version => version, :platform => platform,
            :name => job_name, :build => build, :tags => tags,
            'max-duration' => 3600, 'record-video' => false}]

        assert_equal 'called mock capabilities', sauce.capabilities

        mock_capabilities_class.verify
      end
    end

    describe "#driver" do
      let(:sauce_url) { "http://#{username}:#{access_key}@ondemand.saucelabs.com:80/wd/hub" }

      it "should create a driver" do
        def sauce.capabilities; 'mocked_capabilities'; end
        def sauce.http_client; 'mocked http_client'; end

        mock_driver_class.expect(:for, true,
            [:remote, {:url => sauce_url,
                       :desired_capabilities => 'mocked_capabilities',
                       :http_client => 'mocked http_client'}])

        sauce.driver

        mock_driver_class.verify
      end
    end

    describe "#sidekiq_job_id" do
      it "is available if passed in on init" do
        job_id = SecureRandom.urlsafe_base64
        sauce = SauceLabsWebdriverJob.new options.merge(sidekiq_job_id: job_id)

        assert_equal job_id, sauce.sidekiq_job_id
      end
    end

    describe "#run!" do
      before do
        def sauce.navigate_to_url; @method_calls ||= []; @method_calls << :navigate_to_url; end
        def sauce.hide_passing_tests; @method_calls ||= []; @method_calls << :hide_passing_tests; end
        def sauce.wait_for_completion(*args); @method_calls ||= []; @method_calls << :wait_for_completion; end
        def sauce.save_result; @method_calls ||= []; @method_calls << :save_result; end
        def sauce.quit_driver; @method_calls ||= []; @method_calls << :quit_driver; end
        def sauce.print_message_to_console; @method_calls ||= []; @method_calls << :print_message_to_console; end
        def sauce.method_calls; @method_calls; end
      end

      it "calls methods in correct order" do
        sauce.run!

        expected_method_calls = [:navigate_to_url, :hide_passing_tests,
                                 :wait_for_completion, :save_result,
                                 :quit_driver, :wait_for_completion,
                                 :print_message_to_console]

        assert_equal expected_method_calls, sauce.method_calls
      end
    end

    describe "#upload_to_s3" do
      let(:fake_bucket)  { TestSupport::MockS3Bucket.new }
      let(:results_path) { 'fred/flinstone' }

      before do
        def sauce.build_s3_bucket
          @build_s3_bucket_called = true
          TestSupport::MockS3Bucket.new
        end

        def sauce.build_s3_bucket_called
          @build_s3_bucket_called
        end

        def sauce.build_s3_results; 'random results'; end
      end

      describe "when no results_path is specified" do
        let(:results_path) { nil }

        it "doesn't add any files to the bucket" do
          sauce.upload_to_s3(:bucket => fake_bucket)

          assert_equal 0, fake_bucket.objects.length
        end

        it "doesn't call build_s3_bucket" do
          sauce.upload_to_s3

          refute sauce.build_s3_bucket_called
        end
      end

      it "calls build_s3_bucket if no bucket is provided" do
        sauce.upload_to_s3

        assert sauce.build_s3_bucket_called
      end

      it "uses the bucket if provided" do
        sauce.upload_to_s3(:bucket => fake_bucket)

        refute sauce.build_s3_bucket_called
      end

      it "uploads files" do
        sauce.upload_to_s3(:bucket => fake_bucket)

        assert_equal 1, fake_bucket.objects.length
      end

      it "saves data from build_s3_results" do
        sauce.upload_to_s3(:bucket => fake_bucket)

        expected_dest = results_path + "/#{platform}-#{browser}-#{version}.json"
        expected_dest = expected_dest.downcase.gsub(' ', '_')

        s3_object = fake_bucket.objects[expected_dest]

        assert_equal 'random results', s3_object.source_path
      end
    end
  end
end
