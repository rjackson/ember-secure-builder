require 'dotenv'
require 'sidekiq/cli'
require './lib/ember_secure_builder'

Dotenv.load!

Thread.new do
  begin
    cli = Sidekiq::CLI.instance
    cli.parse(['--require', './lib/ember_secure_builder.rb', '--concurrency', '7'])
    cli.run
  rescue => e
    raise e if $DEBUG
    STDERR.puts e.message
    STDERR.puts e.backtrace.join("\n")
    exit 1
  end
end

run EmberSecureBuilder::RackApp
