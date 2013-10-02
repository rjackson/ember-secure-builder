require 'json'
require 'net/http'
require 'rest_client'

module EmberSecureBuilder
  class SauceLabsJob
    attr_accessor :username, :access_key, :env, :job_detail, :completed,
                  :name, :tags, :test_url, :submit_job_response,
                  :os, :browser, :browser_version

    def initialize(options = nil)
      options ||= {}

      self.env        = options.fetch(:env)        { ENV }
      self.tags       = options.fetch(:tags)       { [] }
      self.name       = options.fetch(:name)       { `git rev-list --max-count=1 HEAD` }
      self.username   = options.fetch(:username)   { env['SAUCE_LABS_USERNAME'] }
      self.access_key = options.fetch(:access_key) { env['SAUCE_LABS_ACCESS_KEY'] }

      self.os              = options.fetch(:os, nil)
      self.browser         = options.fetch(:browser, nil)
      self.test_url        = options.fetch(:test_url, nil)
      self.browser_version = options.fetch(:browser_version, '')
    end

    def base_url
      "https://#{username}:#{access_key}@saucelabs.com/rest/v1/#{username}/"
    end

    def submit_job
      return submit_job_response if submit_job_response

      request_body = {"platforms" => [[os, browser, browser_version]],
                      "url" => test_url, "framework" => "qunit"}

      response = RestClient.post base_url + 'js-tests', request_body.to_json,
                                 :content_type => :json, :accept => :json

      self.submit_job_response = response.body
    end

    def job_detail
      @job_detail || get_job_detail
    end

    def get_job_detail
      response = RestClient.post base_url + 'js-tests/status', submit_job_response,
                                 :content_type => :json, :accept => :json

      status = JSON.parse response.body

      self.completed  = status['completed']
      self.job_detail = status['js tests'].first
    end

    def completed(force_refresh = false)
      get_job_detail if force_refresh

      @completed
    end

    def wait_for_completion(options = nil)
      options ||= {}

      timeout    = options.fetch(:timeout, 900)
      sleep_time = options.fetch(:sleep_time, 5)

      start_time = Time.now

      loop do
        get_job_detail

        puts "Current Status: #{job_detail}"

        break if completed
        break if Time.now - start_time > timeout

        puts "Looping Again..."

        sleep sleep_time
      end
    end

    def passed?
      job_detail['result'] && job_detail['result']['failed'] == 0
    end

    def update_job_details
      body = {tags: tags, build: name}

      job_id = job_detail['url'][%r{jobs/.+$}]

      if completed
        body[:passed] = passed?
      end

      response = RestClient.put base_url + job_id, body.to_json,
                                 :content_type => :json, :accept => :json
    end
  end
end
