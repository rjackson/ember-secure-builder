[![Build Status](https://travis-ci.org/rjackson/ember-secure-builder.png?branch=master)](https://travis-ci.org/rjackson/ember-secure-builder)

Purpose
=======

This repo is for setting up a cloud based system to accecpt GH hook callbacks
and generate ember assets without evaluating any insecure project files.

How
===

We will be using a known good version of the build system (in other words we will
use the master branch of https://github.com/emberjs/ember.js) and only replace the
the `packages` folder from the submitted Pull Request.

OK, So REALLY HOW?
==================

```
 Rack App
    |
    |
    v
 Sidekiq (backed by Redis)
    |
    |
    v
 Workers
```

Needed Infrastructure
=====================

We will need a single small EC2 instance running a few different services/workers:

Redis Server
Rack App (github webhook receiver)
Workers
  Asset Builder Container
  SauceLabs Worker Container

Sauce Labs Info
===============
Submitting new jobs via REST API:

```ruby
require 'uri'
require 'net/http'

# loads the ENV vars needed below from a `.env` file
require 'dotenv'
Dotenv.load

uri = URI.parse("https://saucelabs.com/rest/v1/#{ENV['SAUCE_LABS_USERNAME']}/js-tests")

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri.path)
request.basic_auth(ENV['SAUCE_LABS_USERNAME'], ENV['SAUCE_LABS_ACCESS_KEY'])
request.add_field('Content-Type', 'application/json')
request.body = '{
  "platforms": [
    ["Windows 7", "iehta", "10"],
    ["Windows 7", "iehta", "9"],
    ["Windows 7", "iehta", "8"],
    ["Windows XP", "iehta", "7"],
    ["Windows XP", "iehta", "6"],
    ["Linux", "googlechrome", ""],
    ["Linux", "firefox", "23"],
    ["OS X 10.8", "safari", "6"]
  ],
  "url": "https://s3.amazonaws.com/rwjblue-ember-dev-test/canary/tests.html",
  "framework": "qunit"
}'

response = http.request(request)
```

Supporting Info:
  * https://saucelabs.com/docs/rest#jsunit
  * https://github.com/saucelabs/sauce_whisk (REST API gem)
  * http://saucelabs.com/docs/status-images

Tasks TODO
==========
* Implement AssetBuildingWorker as follows:
  * **DONE** Clone known good `ember.js` repo.
  * **DONE** Clone 'suspect' PR repo.
  * **DONE** Checkout PR branch on 'suspect' repo.
  * **DONE** Copy `packages/` directory from 'suspect' repo into known good repo.
  * **DONE** Run `rake dist`
  * **DONE** Publish assets VIA `EmberDev::Publish.to_s3`.
  * Queue SauceLabs job.
* Add SauceLabsWorker
  * Manage subaccount keys (one key per worker).
  * Shell out to `grunt-saucelabs` for actual testing.
