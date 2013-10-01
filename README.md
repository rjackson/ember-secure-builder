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
