redis: redis-server --bind 127.0.0.1
sidekiq-sauce: dotenv sidekiq --require ./lib/ember_secure_builder.rb --concurrency 7 --queue sauce_labs
sidekiq-default: dotenv sidekiq --require ./lib/ember_secure_builder.rb --concurrency 5 --queue default
web: rackup config.ru
guard: guard -i
