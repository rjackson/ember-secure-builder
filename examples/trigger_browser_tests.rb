require 'dotenv'
require 'rest-client'

Dotenv.load

params = {'repo' => 'emberjs/ember.js',
          'project_name' => 'Ember',
          'tags' => 'ember',
          'commit_sha' => '2c42db1',
          'test_url' => 'https://s3.amazonaws.com/rwjblue-ember-dev-test/ember/pull-request/2409/ember-tests.html',
          'results_path' => 'ember/pull-request/2409/triggered-results'}

RestClient.post 'http://localhost:9292/queue-browser-tests', params
