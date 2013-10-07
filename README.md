[![Build Status](https://travis-ci.org/rjackson/ember-secure-builder.png?branch=master)](https://travis-ci.org/rjackson/ember-secure-builder)

Usage
=====

1. Run the `RackApp`:

```sh
rackup config.ru
```

2. Run the `Sidekiq` worker process:

```sh
# set concurrency to your maximum number of SauceLabs concurrent workers
sidekiq --require ./lib/ember_secure_builder.rb --concurrency 2
```

3. Post the repository and pull request number you are attempting to test.

```ruby
require 'octokit'
require 'rest-client'

pull_requests = Octokit.pull_requests 'emberjs/ember.js'
pull_requests.each do |pr|
  RestClient.post 'http://localhost:9292/build', repo: 'emberjs/ember.js', perform_cross_browser_tests: true, pull_request_number: pr.number
end
```

4. Watch the SauceLabs site for build pass/fail status: https://saucelabs.com/u/rwjblue

Tasks TODO
==========
* **DONE** Implement Hooks for Asset Build (to be used by Travis not Github).
* **DONE** Queue Sauce Labs jobs after asset build is completed.
* Create UI for reviewing historical Sauce Labs runs for a specific build.
  * Save run details to JSON file in S3 in sub-folder of assets directory.
  * Create a simple Ember app to display the status of a given commit/PR.
  * Needs to show browsers along with failure status and any errors.

Pre-Deploy Steps
* Decide on a better project name.
* Move project under `emberjs` on Github.
* Create S3 bucket for PR builds (`pr-builds.emberjs.com`?)
* Create DNS entries
  * The rack endpoint (aka `project_name.emberjs.com`)
  * The S3 bucket for PR builds
  * The static site Ember app for displaying cross-browser results.
