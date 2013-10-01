require 'json'
require 'securerandom'
require 'spec_helper'

module EmberSecureBuilder
  describe SauceLabsJob do
    include WebMock::API

    let(:sauce) { SauceLabsJob.new( username: username, access_key: access_key, os: os, browser: browser, browser_version: browser_version, test_url: url, name: job_name) }
    let(:username)    { SecureRandom.urlsafe_base64 }
    let(:access_key)  { SecureRandom.urlsafe_base64 }
    let(:url)         { "https://blahblah.com/something/#{SecureRandom.urlsafe_base64}" }
    let(:job_name)    { SecureRandom.urlsafe_base64 }

    let(:platforms)       { [[os, browser, browser_version]] }
    let(:os)              { "Windows 7" }
    let(:browser)         { "iehta" }
    let(:browser_version) { "10" }

    describe "#username" do
      it "accepts the SauceLabsJob username on init" do
        sauce = SauceLabsJob.new(username: 'blah')

        assert_equal 'blah', sauce.username
      end

      it "pulls from ENV if not specified" do
        sauce = SauceLabsJob.new env: {'SAUCE_LABS_USERNAME' => 'blah'}

        assert_equal 'blah', sauce.username
      end
    end

    describe "#access_key" do
      it "accepts the SauceLabsJob access_key on init" do
        sauce = SauceLabsJob.new(access_key: 'blah')

        assert_equal 'blah', sauce.access_key
      end

      it "pulls from ENV if not specified" do
        sauce = SauceLabsJob.new env: {'SAUCE_LABS_ACCESS_KEY' => 'blah'}

        assert_equal 'blah', sauce.access_key
      end
    end

    describe "#name" do
      it "saves the name when provided on init" do
        sauce = SauceLabsJob.new(name: 'blah')

        assert_equal 'blah', sauce.name
      end

      it "uses last commit SHA if not specified" do
        sauce = SauceLabsJob.new

        assert_equal `git rev-list --max-count=1 HEAD`, sauce.name
      end
    end

    describe "#tags" do
      it "saves the tags when provided on init" do
        tags = ['fred', 'barney']
        sauce = SauceLabsJob.new(tags: tags)

        assert_equal tags, sauce.tags
      end

      it "uses empty array if not specified" do
        sauce = SauceLabsJob.new

        assert_equal [], sauce.tags
      end
    end

    describe "#get_job_detail" do
      let(:request) do
        stub_request(:post, "https://#{username}:#{access_key}@saucelabs.com/rest/v1/#{username}/js-tests/status")
          .with(:body => request_body.to_json, :headers => {"Content-Type" => 'application/json'})
          .to_return(:body => response_body.to_json, :headers => {"Content-Type" => 'application/json'})
      end

      let(:request_body) { {"js tests" => [ SecureRandom.urlsafe_base64 ] } }
      let(:response_body) { {"js tests" => [ SecureRandom.urlsafe_base64 ] } }

      before do
        sauce.submit_job_response = request_body.to_json
      end

      it "should request status" do
        request

        sauce.get_job_detail

        assert_requested request
      end

      it "should set job_detail from the request" do
        request

        sauce.get_job_detail

        assert_equal response_body['js tests'].first, sauce.job_detail
      end

      it "should set completed to false if not included in response" do
        request

        sauce.get_job_detail

        refute sauce.completed
      end

      it "should set completed to true if included in response" do
        response_body['completed'] = true
        request

        sauce.get_job_detail

        assert sauce.completed
      end
    end

    describe "#update_run_details" do
      let(:request) do
        stub_request(:put, "https://#{username}:#{access_key}@saucelabs.com/rest/v1/#{username}/#{sauce.job_detail['url']}")
          .with(:body => {"tags" => [], "build" => job_name, "passed" => passed}.to_json, :headers => {"Content-Type" => 'application/json'})
      end

      let(:job_id) { SecureRandom.urlsafe_base64 }
      let(:passed) { sauce.job_detail['result']['failed'] == 0 }

      before do
        sauce.job_detail = {"url" => "jobs/#{job_id}", "result"=> {"failed" => [0,1].sample} }

        request
      end

      it "should update each runs details" do
        sauce.update_job_details

        assert_requested request
      end
    end

    describe "#submit_job" do
      let(:request) do
        stub_request(:post, "https://#{username}:#{access_key}@saucelabs.com/rest/v1/#{username}/js-tests")
          .with(:body => request_body, :headers => {"Content-Type" => 'application/json'})
          .to_return(:body => response_body.to_json, :headers => {"Content-Type" => 'application/json'})
      end

      let(:request_body)  { {"platforms" => platforms, "url" => url, "framework" => "qunit"} }
      let(:response_body) { {"js tests" => [ SecureRandom.urlsafe_base64 ]} }

      before do
        request
      end

      it "should POST to SauceLabs REST js-test endpoint" do
        sauce.submit_job

        assert_requested request
      end

      it "should only POST once" do
        sauce.submit_job
        sauce.submit_job

        assert_requested request
      end
    end
  end
end
