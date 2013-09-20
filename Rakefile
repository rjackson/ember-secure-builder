require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "spec"
  t.test_files = FileList['spec/**/*_spec.rb']
end

desc "start server (main executable)"
task :start do
  sh %{bin/github_post_receive_server}
end

desc "start server under thin (rackup)"
task :thin do
  sh %{thin -R bin/github_post_receive_server.ru -p 9001 start}
end

desc "run specs"
task :default => :test
