require 'json'
require 'net/http'

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
      "https://saucelabs.com/rest/v1/#{username}"
    end

    def submit_job
      return submit_job_response if submit_job_response

      uri = URI.parse("#{base_url}/js-tests")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path)
      request.basic_auth(username, access_key)
      request.add_field('Content-Type', 'application/json')
      request.body = {"platforms" => [[os, browser, browser_version]],
                      "url" => test_url, "framework" => "qunit"}.to_json

      self.submit_job_response = http.request(request).body
    end

    def job_detail
      @job_detail || get_job_detail
    end

    def get_job_detail
      uri = URI.parse("#{base_url}/js-tests/status")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path)
      request.basic_auth(username, access_key)
      request.add_field('Content-Type', 'application/json')
      request.body = submit_job_response

      response  = http.request(request)

      status = JSON.parse(response.body)

      self.completed  = status['completed']
      self.job_detail = status['js tests'].first
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

      run_id = job_detail['url'][%r{jobs/.+$}]

      if completed
        body[:passed] = passed?
      end

      uri = URI.parse("#{base_url}/#{run_id}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Put.new(uri.path)
      request.basic_auth(username, access_key)
      request.add_field('Content-Type', 'application/json')
      request.body = body.to_json

      response = http.request(request)
    end
  end
end
