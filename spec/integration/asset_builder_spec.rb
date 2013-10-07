require 'spec_helper'
require 'bundler'

module EmberSecureBuilder
  describe "AssetBuilder can actually generate Assets." do
    let(:builder) { AssetBuilder.new(project) }
    let(:known_good_asset) { @known_good_asset }
    let(:suspect_branch) { builder.good_branch }
    let(:suspect_repo_url) { builder.good_repo }

    before do
      Dir.mktmpdir do |tmpdir|
        local_path = Pathname.new(tmpdir).join(project)
        system("git clone --branch #{builder.good_branch} --depth=1 #{suspect_repo_url} #{local_path}")

        Dir.chdir local_path.to_s do
          Bundler.with_clean_env do
            assert system("bundle install")
            assert system("rake dist")
          end
        end

        @known_good_asset = File.read(local_path.join(asset_path))
      end

      builder.suspect_repo   = suspect_repo_url
      builder.suspect_branch = suspect_branch
    end

    describe "for emberjs/ember.js" do
      let(:project) { 'emberjs/ember.js' }
      let(:asset_path) { 'dist/ember.js' }

      it "should match the known good assets" do
        assert builder.build

        assert_equal known_good_asset, File.read(builder.asset_source_path.join('ember.js'))
      end
    end

    describe "for emberjs/data" do
      let(:project) { 'emberjs/data' }
      let(:asset_path) { 'dist/ember-data.js' }

      it "should match the known good assets" do
        assert builder.build

        assert_equal known_good_asset, File.read(builder.asset_source_path.join('ember-data.js'))
      end
    end
  end
end
