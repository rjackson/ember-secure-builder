require 'tmpdir'
require 'fileutils'

module EmberSecureBuilder
  class AssetBuilder
    attr_accessor :suspect_repo, :suspect_branch, :work_dir, :debug

    def initialize(suspect_repo_url, suspect_repo_branch, options = nil)
      options ||= {}

      self.suspect_repo   = suspect_repo_url
      self.suspect_branch = suspect_repo_branch

      self.debug = options.fetch(:debug) { true }
      self.work_dir = options.fetch(:work_dir) { build_work_dir }
    end

    def cleanup
      FileUtils.remove_entry_secure work_dir if File.exists? work_dir
    end

    def clone_suspect_repo
      command = "git clone --depth=1 --branch=#{suspect_branch} #{suspect_repo} suspect"

      puts command if debug
    end

    private

    def build_work_dir
      dir = Dir.mktmpdir

      at_exit{ cleanup }

      dir
    end

  end
end
