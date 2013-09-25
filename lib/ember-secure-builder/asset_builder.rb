require 'tmpdir'
require 'fileutils'

module EmberSecureBuilder
  class AssetBuilder
    attr_accessor :suspect_repo, :suspect_branch,
                  :good_repo,    :good_branch,
                  :work_dir, :debug

    def initialize(suspect_repo_url, suspect_repo_branch, options = nil)
      options ||= {}

      self.suspect_repo   = suspect_repo_url
      self.suspect_branch = suspect_repo_branch

      self.good_repo   = options.fetch(:good_repo) {  'git@github.com:emberjs/ember.js.git' }
      self.good_branch = options.fetch(:good_branch) {  'master' }

      self.debug       = options.fetch(:debug) { true }
      self.work_dir    = options.fetch(:work_dir) { build_work_dir }
    end

    def cleanup
      FileUtils.remove_entry_secure work_dir if File.exists? work_dir
    end

    def clone_repos
      @cloned ||= clone_suspect_repo && clone_good_repo
    end

    def copy_suspect_packages
      clone_repos

      FileUtils.rm_r good_repo_local_path.join('packages')
      FileUtils.cp_r suspect_repo_local_path.join('packages').to_s, good_repo_local_path.to_s
    end

    def build
      clone_repos

      Dir.chdir good_repo_local_path do
        system('rake dist')
      end
    end

    private

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
      dir = Dir.mktmpdir

      at_exit{ cleanup }

      Pathname.new(dir)
    end

    def upload(source_path, destination_path)
      secret_vars = Dotenv::Environment.new('.env')

      s3 = AWS::S3.new(:access_key_id     => secret_vars['S3_ACCESS_KEY_ID'],
                       :secret_access_key => secret_vars['S3_SECRET_ACCESS_KEY'])

      bucket = s3.buckets[secret_vars['S3_BUCKET_NAME']]

      obj = bucket.objects[destination_path]
      obj.write(source_path, {:content_type => 'text/javascript'})
    end
  end
end
