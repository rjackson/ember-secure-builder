redis: redis-server --bind 127.0.0.1
sidekiq: dotenv sidekiq --require ./lib/ember_secure_builder.rb --concurrency 7 --queue sauce_labs
sidekiq: dotenv sidekiq --require ./lib/ember_secure_builder.rb --queue default
web: rackup config.ru
guard: guard -i
