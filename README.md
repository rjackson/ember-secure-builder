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
  Asset Builder
  SauceLabs Worker

Tasks TODO
==========
* Implement Hooks for Asset Build (to be used by Travis not Github).
* Queue Sauce Labs jobs after asset build is completed.
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
