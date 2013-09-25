require 'spec_helper'
require 'bundler'

module EmberSecureBuilder
  describe "AssetBuilder can actually generate Assets." do
    let(:known_good_asset) { @known_good_asset }
    let(:suspect_branch) { 'master' }
    let(:suspect_repo_url) { "git@github.com:emberjs/ember.js.git" }

    before do
      Dir.mktmpdir do |tmpdir|
        local_path = Pathname.new(tmpdir).join('ember.js')
        system("git clone --depth=1 #{suspect_repo_url} #{local_path}")

        Dir.chdir local_path.to_s do
          Bundler.with_clean_env do
            assert system("bundle install")
            assert system("rake dist")
          end
        end

        @known_good_asset = File.read(local_path.join('dist/ember.js'))
      end
    end

    it "should match the known good assets" do
      builder = AssetBuilder.new(suspect_repo_url, suspect_branch)

      assert builder.build

      assert_equal known_good_asset, File.read(builder.asset_source_path)
    end
  end
end
