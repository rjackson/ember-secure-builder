redis: redis-server --bind 127.0.0.1
sidekiq: dotenv sidekiq --require ./lib/ember_secure_builder.rb --concurrency 7
web: rackup config.ru
guard: guard -i
