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
  * Possibly a Simple Rack App serving JSON out of Redis to an Ember app.
  * Needs to show browsers along with failure status and any errors.
