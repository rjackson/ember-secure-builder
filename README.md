[![Build Status](https://travis-ci.org/rjackson/ember-secure-builder.png?branch=master)](https://travis-ci.org/rjackson/ember-secure-builder)

##Purpose

To run supporting tasks for Ember development that cannot be done from within
TravisCI. The tasks are mostly related to publishing builds and cross-browser
testing at this point, but could extend to just about anything that we need.

The main functions provided now are:

* To build and publish builds from pull requests.

  This must be done carefully to prevent exposing our secret keys to the pull
  request author (and is why Travis disables secure environment variables for
  PR's). The route that we have chosen is to use a known good version of a the
  base repository ('emberjs/ember.js' or 'emberjs/data') and import the `packages`
  from the pull request repo/branch. This prevents any of the pull request's code
  from being executed.

* To run cross-browser tests.

  To ensure that we do not introduce regressions for specific browsers we need to run
  our test suite against all supported browsers. We are using [Sauce Labs](http://saucelabs.com)
  to run the full test suite on each supported browser.

##Browsers Tested

You can check the current default platforms in `lib/ember_secure_builder/sauce_labs_webdriver_job.rb`,
but the following is the current listing (as of 2013/10/07):

```ruby
[
  {:browser => :chrome,            :platform => 'OS X 10.8'},
  {:browser => :safari,            :platform => 'OS X 10.8',  :version => 6},
  {:browser => :iphone,            :platform => 'OS X 10.8',  :version => 6,     'device-orientation' => 'landscape'},
  {:browser => :ipad,              :platform => 'OS X 10.8',  :version => 6,     'device-orientation' => 'landscape'},
  {:browser => :firefox,           :platform => 'Windows 7',  :version => 24},
  {:browser => :internet_explorer, :platform => 'Windows 7',  :version => 10},
  {:browser => :internet_explorer, :platform => 'Windows 7',  :version => 9},
  {:browser => :internet_explorer, :platform => 'Windows 7',  :version => 8},
]
```

##Usage

```sh
cp .env.sample .env
```

Edit `.env` to set your S3 and SauceLabs credentials.

###With Foreman

```sh
foreman start
```

###Manually


```sh
# Start redis
redis-server

# Run the `RackApp`:
rackup config.ru

# Run the `Sidekiq` worker process:
# set concurrency to your maximum number of SauceLabs concurrent workers
sidekiq --require ./lib/ember_secure_builder.rb --concurrency 2
```

Post the repository and pull request number you are attempting to test (example runs all pull-requests).

```ruby
require 'octokit'
require 'rest-client'

pull_requests = Octokit.pull_requests 'emberjs/ember.js'
pull_requests.each do |pr|
  RestClient.post 'http://localhost:9292/build', repo: 'emberjs/ember.js', perform_cross_browser_tests: true, pull_request_number: pr.number
end
```

Watch the SauceLabs site for build pass/fail status: https://saucelabs.com/u/rwjblue

##Webhook Details

The webhook endpoint (`EmberSecureBuilder::RackApp`) uses the following URL endpoints:

* POST `/build`
  * `repo` (**required**) - The parent projects repo in Organization/Project format (i.e. 'emberjs/ember.js' or 'emberjs/data').
  * `pull_request_number` (**required**) - The pull request number to build.
  * `perform_cross_browser_tests` - Should we perform cross-browser tests after the build is published? ('true' == yes, anything else == no).

* POST `/queue-browser-tests`
  * `commit_sha` (**required**) - This will be used as the build ID.
  * `test_url` (**required**) - The url to run the tests against.
  * `repo` (**required**) - The parent projects repo in Organization/Project format (i.e. 'emberjs/ember.js' or 'emberjs/data').
  * `project_name` - This will be used for the Sauce Labs session name.
  * `tags` - This will be used as tags with Sauce Labs (to make filtering easier).
  * `results_path` - The relative path within the S3 bucket to place the results.

##Tasks TODO

* **DONE** Make work properly for Ember Data.
* **DONE** Save results off to S3 for each Sauce Labs run (namespaced under the PR path).
* **DONE** Create Webhook for triggering the Sauce Labs jobs directly (without going through AssetBuilder first).
* Create comment in Github to indicate pass/fail status when all workers are done (or incrementally?).
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
