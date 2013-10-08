require 'selenium-webdriver'
require 'connection_pool'
require 'rest_client'
require 'json'

module EmberSecureBuilder
  class SauceLabsWebdriverJob
    attr_accessor :username, :access_key,
      :browser, :platform, :version,
      :name, :url, :build, :tags, :env,
      :driver_class, :capabilities_class,
      :results_path

    def self.default_platforms
      [
        {:browser => :chrome,            :platform => 'OS X 10.8'},
        {:browser => :safari,            :platform => 'OS X 10.8',  :version => 6},
        {:browser => :iphone,            :platform => 'OS X 10.8',  :version => 6,     'device-orientation' => 'landscape'},
        {:browser => :ipad,              :platform => 'OS X 10.8',  :version => 6,     'device-orientation' => 'landscape'},
        {:browser => :firefox,           :platform => 'Windows 7',  :version => 24},
        {:browser => :opera,             :platform => 'Windows 7',  :version => 12},
        {:browser => :internet_explorer, :platform => 'Windows 7',  :version => 10},
        {:browser => :internet_explorer, :platform => 'Windows 7',  :version => 9},
        {:browser => :internet_explorer, :platform => 'Windows 7',  :version => 8},
        {:browser => :internet_explorer, :platform => 'Windows XP', :version => 7},
        {:browser => :internet_explorer, :platform => 'Windows XP', :version => 6},
      ]
    end

    def self.all_platforms
      default_platforms + [
        {:browser => :android,           :platform => 'Linux',      :version => '4.0', 'device-orientation' => 'landscape'},
      ]
    end

    def self. run!(options)
      new(options).run!
    end

    def initialize(options = nil)
      options = symbolize_hash_keys(options)

      self.env        = options.fetch(:env)        { ENV }

      self.url        = options[:url]
      self.browser    = options[:browser]
      self.platform   = options[:platform]
      self.version    = options.fetch(:version, '')
      self.results_path = options.fetch(:results_path, nil)

      self.tags       = options.fetch(:tags, [])
      self.build      = options.fetch(:build, '')

      self.name       = options.fetch(:name)       { `git rev-list --max-count=1 HEAD` }
      self.username   = options.fetch(:username)   { env['SAUCE_LABS_USERNAME'] }
      self.access_key = options.fetch(:access_key) { env['SAUCE_LABS_ACCESS_KEY'] }

      # dependency injection for testing
      self.driver_class       = options.fetch(:driver_class, Selenium::WebDriver)
      self.capabilities_class = options.fetch(:capabilities_class, Selenium::WebDriver::Remote::Capabilities)
    end

    def capabilities
      @capabilities ||= capabilities_class.send(browser.to_sym,
                                                {:version => version,
                                                 :platform => platform,
                                                 :name => name,
                                                 :build => build,
                                                 :tags => tags,
                                                 'max-duration' => 3600,
                                                 "record-video" => false})
    end

    def driver
      @driver ||= driver_class.for :remote,
                                   :url => "http://#{username}:#{access_key}@ondemand.saucelabs.com:80/wd/hub",
                                   :desired_capabilities => capabilities,
                                   :http_client => http_client
    end

    def http_client
      @http_client ||= build_http_client
    end

    def quit_driver
      driver.quit
    end

    def run!
      navigate_to_url
      hide_passing_tests
      wait_for_completion
      save_result
      quit_driver
      wait_for_completion break_on_result: false

      print_message_to_console
    end

    def navigate_to_url
      driver.get url
    end

    def hide_passing_tests
      element = driver.find_element :id, 'qunit-tests'
      driver.execute_script("arguments[0].className = ' hidepass'", element)
    end

    def wait_for_completion(options = nil)
      options ||= {}

      timeout         = options.fetch(:timeout, 90)
      sleep_time      = options.fetch(:sleep_time, 2)
      break_on_result = options.fetch(:break_on_result, true)

      start = Time.now

      loop do
        elapsed_time   = Time.now - start

        if break_on_result
          break if last_assertion_millis.nil? && elapsed_time > 90
          break if assertion_timeout? timeout
          break if result
        else
          break if completed?
        end

        sleep sleep_time
      end
    end

    def result
      @result ||= driver.execute_script("return window.globalTestResults;")
    end

    def assertion_timeout?(timeout, last_assertion_millis = last_assertion_millis)
      return unless last_assertion_millis

      last_assertion_time       = Time.at(last_assertion_millis/1000)
      time_since_last_assertion = Time.now - last_assertion_time

      last_assertion_time && time_since_last_assertion > timeout
    end

    def last_assertion_millis
      driver.execute_script("return window.lastAssertionTime;")
    end

    def passed?
      result && result['failed'] == 0
    end

    def job_id
      driver.instance_variable_get("@bridge").instance_variable_get("@session_id")
    end

    def save_result
      save_result_to_sauce_labs
      upload_to_s3
    end

    def save_result_to_sauce_labs
      body = {passed: passed?}

      RestClient.put sauce_labs_job_url, body.to_json, :content_type => :json, :accept => :json
    end

    def print_message_to_console
      pass_fail_prefix = passed? ? 'Tests Passed! ' : 'Tests Failed! '

      puts "#{pass_fail_prefix} (#{platform} - #{browser} - #{version})"
    end

    def completed?
      response = RestClient.get sauce_labs_job_url, :content_type => :json, :accept => :json
      payload  = JSON.parse(response.body)

      payload['status'] == 'complete'
    end

    def upload_to_s3(options = {})
      return unless results_path

      bucket = options.fetch(:bucket) { build_s3_bucket }

      destination_path = results_path + "/#{platform}-#{browser}-#{version}.json"

      obj = bucket.objects[destination_path.gsub(' ', '_').downcase]
      obj.write(build_s3_results, {:content_type => 'application/json'})
    end

    def build_s3_results
      {browser: browser, test_url: url,
       platform: platform, version: version,
       result: result, passed: passed?,
       build: build, tags: tags}.to_json
    end

    private

    def sauce_labs_job_url
      "https://#{username}:#{access_key}@saucelabs.com/rest/v1/#{username}/jobs/#{job_id}"
    end

    def symbolize_hash_keys(input)
      input ||= {}

      Hash[input.map{|key, value| [key.to_sym, value]}]
    end

    def build_http_client
      client = Selenium::WebDriver::Remote::Http::Default.new
      client.timeout = 180
      client
    end

    def build_s3_bucket
      s3 = AWS::S3.new(:access_key_id => env['S3_ACCESS_KEY_ID'],
                       :secret_access_key => env['S3_SECRET_ACCESS_KEY'])

      s3.buckets[env['S3_BUCKET_NAME']]
    end
  end
end
