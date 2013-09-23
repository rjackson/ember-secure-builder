require 'pathname'
require 'bundler/setup'
require 'dotenv/tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "spec"
  t.test_files = FileList['spec/**/*_spec.rb']
end

task :clear_test_repos do
  FileUtils.rm_rf 'spec/support/test_repos'
end

task :setup_test_repos => :clear_test_repos do
  repo_base_path = Pathname.new('spec/support/test_repos').expand_path
  abort 'Repos already setup' if repo_base_path.exist?

  FileUtils.mkdir_p repo_base_path.to_s
  Dir.chdir repo_base_path.realpath
  sh('mkdir -p suspect_repo_1/packages/some-random-package')
  Dir.chdir repo_base_path.join('suspect_repo_1').realpath
  sh('git init .')
  sh('git config user.email "test@example.com"')
  sh('git config user.name "Test User"')
  sh('touch this_should_NOT_be_copied')
  sh('touch packages/some-random-package/this_should_be_copied')
  sh('git add -A')
  sh('git commit -m "Initial commit."')
  sh('git checkout -b some_feature_branch')
  sh('mkdir -p packages/some-new-package/')
  sh('touch packages/some-new-package/this_should_be_copied')
  sh('touch this_also_should_NOT_be_copied')
  sh('git add -A')
  sh('git commit -m "Add some-new-package."')

  Dir.chdir repo_base_path.realpath
  sh('mkdir -p good_repo/packages/some-good-package')
  Dir.chdir repo_base_path.join('good_repo').realpath
  sh('git init .')
  sh('git config user.email "test@example.com"')
  sh('git config user.name "Test User"')
  sh('touch some_good_file')
  sh('touch packages/some-good-package/some_package_file')
  sh('git add -A')
  sh('git commit -m "Initial commit."')
end

desc "run specs"
task :default => :test
