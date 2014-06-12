require 'tmpdir'
require 'fileutils'

require 'aws-sdk'

module EmberSecureBuilder
  class AssetBuilder
    class CloneRepoError < StandardError; end

    attr_accessor :suspect_repo, :suspect_branch, :project,
                  :work_dir, :debug, :env,
                  :project, :good_repo, :good_branch,
                  :asset_source_path, :asset_destination_path,
                  :pull_request_number, :last_suspect_repo_commit,
                  :cross_browser_test_batch_class, :disable_auto_cleanup,
                  :pull_request_details

    def self.publish_pull_request(repository, pull_request_number, perform_cross_browser_tests = false)
      Dir.mktmpdir do |tmpdir|
        builder = new(repository, disable_auto_cleanup: true, work_dir: Pathname.new(tmpdir))
        builder.load_from_pull_request(repository, pull_request_number)
        builder.build
        builder.upload

        if perform_cross_browser_tests
          builder.queue_cross_browser_tests
        end
      end
    end

    def initialize(project, options = nil)
      self.project = project

      options    ||= {}

      self.env            = options.fetch(:env) { ENV }
      self.suspect_repo   = options.fetch(:suspect_repo, nil)
      self.suspect_branch = options.fetch(:suspect_branch, nil)
      self.good_repo      = options.fetch(:good_repo, nil)
      self.good_branch    = options.fetch(:good_branch, nil)

      self.debug       = options.fetch(:debug) { true }
      self.work_dir    = options.fetch(:work_dir) { build_work_dir }

      self.asset_source_path      = options[:asset_source_path]
      self.disable_auto_cleanup   = options.fetch(:disable_auto_cleanup, false)
      self.asset_destination_path = options[:asset_destination_path]
      self.cross_browser_test_batch_class = options.fetch(:cross_browser_test_batch_class, CrossBrowserTestBatch)
    end

    def load_from_pull_request(repo, pull_request_number)
      prefix = 'https://github.com/'

      require 'octokit'
      pr = Octokit.pull_request repo, pull_request_number

      self.suspect_repo             = prefix + pr.head.repo.full_name
      self.suspect_branch           = pr.head.ref
      self.pull_request_number      = pull_request_number
      self.pull_request_details     = pr
      self.last_suspect_repo_commit = pr.head.sha
    end

    def last_suspect_repo_commit
      @last_suspect_repo_commit ||= begin
                                      prefix = 'https://github.com/'

                                      require 'octokit'
                                      branch = Octokit.branch suspect_repo.sub(prefix, ''), suspect_branch

                                      branch.commit.sha
                                    end
    end

    def cleanup
      FileUtils.remove_entry_secure work_dir if File.exists? work_dir
    end

    def clone_repos
      @cloned ||= clone_suspect_repo && clone_good_repo
    end

    def copy_suspect_packages
      raise CloneRepoError, "Can't clone repos." unless clone_repos

      FileUtils.rm_r good_repo_local_path.join('packages')
      FileUtils.cp_r suspect_repo_local_path.join('packages').to_s, good_repo_local_path.to_s
    end

    def cli_build
      clone_repos
      copy_suspect_packages

      Bundler.with_clean_env do
        system("cd #{good_repo_local_path} && npm install && ember build --environment production")
      end
    end

    def grunt_build
      clone_repos
      copy_suspect_packages

      Bundler.with_clean_env do
        system("cd #{good_repo_local_path} && npm install && grunt dist")
      end
    end

    def build
      if project.match(/data/)
        grunt_build
      else
        cli_build
      end
    end

    def asset_source_path
      @asset_source_path ||= good_repo_local_path.join('dist')
    end

    def asset_destination_path
      @asset_destination_path ||= "#{project_prefix}/pull-request/#{pull_request_number}"
    end

    def upload(options = {})
      bucket = options.fetch(:bucket) { build_s3_bucket }

      project_files.each do |file|
        type = file.end_with?('.js') ? 'text/javascript' : 'text/html'

        obj = bucket.objects[asset_destination_path + "/#{file}"]
        obj.write(asset_source_path.join(file), {:content_type => type})
      end
    end

    def good_repo
      @good_repo ||= default_good_repo
    end

    def good_branch
      @good_branch ||= default_good_branch
    end

    def queue_cross_browser_tests(batch_class = CrossBrowserTestBatch)
      batch_class.queue cross_browser_test_defaults
    end

    def cross_browser_test_defaults
      options = {:tags => [project_prefix],
                 :url  => test_url,
                 :build => last_suspect_repo_commit,
                 :results_path => asset_destination_path,
                 :name => project_name,
                 :repo_url => suspect_repo,
                 :commit_url => suspect_repo + "/commit/#{last_suspect_repo_commit}"
      }

      if pull_request_number
        options[:name] += " PR ##{pull_request_number}"
        options[:tags] << "PR ##{pull_request_number}"
        options[:pull_request_url] = good_repo + "/pull/#{pull_request_number}"
      else
        options[:tags] << "#{suspect_branch}"
      end

      options
    end

    private

    def project_details
      case project
      when 'emberjs/ember.js'
        {repo: 'https://github.com/emberjs/ember.js',
         branch: 'master',
         name: 'Ember',
         prefix: 'ember',
         files: %w{ember.js ember-spade.js ember-tests.js ember-tests.html}
        }
      when 'emberjs/data'
        {repo: 'https://github.com/emberjs/data',
         branch: 'master',
         name: 'Ember Data',
         prefix: 'ember-data',
         files: %w{ember-spade.js ember-data-tests.js ember-data-tests.html}
        }
      end
    end

    def project_name
      project_details[:name]
    end

    def project_prefix
      project_details[:prefix]
    end

    def project_files
      project_details[:files]
    end

    def default_good_repo
      project_details[:repo]
    end

    def default_good_branch
      project_details[:branch]
    end

    def test_url
      "https://s3.amazonaws.com/#{bucket_name}/#{asset_destination_path}/#{project_prefix}-tests.html"
    end

    def clone_suspect_repo
      clone_repo suspect_repo, suspect_branch, suspect_repo_local_path
    end

    def clone_good_repo
      clone_repo good_repo, good_branch, good_repo_local_path
    end

    def good_repo_local_path
      work_dir.join('good')
    end

    def suspect_repo_local_path
      work_dir.join('suspect')
    end

    def clone_repo(url, branch, path)
      command = "git clone --quiet --depth=1 --branch=#{branch} #{url} #{path}"

      puts command if debug
      system(command)
    end

    def build_work_dir
      dir = Pathname.new(Dir.mktmpdir)

      dir.mkpath unless dir.directory?

      at_exit{ cleanup } unless disable_auto_cleanup

      dir
    end

    def bucket_name
      @bucket_name ||= env['S3_BUCKET_NAME']
    end

    def build_s3_bucket
      s3 = AWS::S3.new(:access_key_id => env['S3_ACCESS_KEY_ID'],
                       :secret_access_key => env['S3_SECRET_ACCESS_KEY'])

      s3.buckets[bucket_name]
    end
  end
end
