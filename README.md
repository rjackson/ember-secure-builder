[![Build Status](https://travis-ci.org/rjackson/ember-secure-builder.png?branch=master)](https://travis-ci.org/rjackson/ember-secure-builder)

Basic Infrastructure
=====================
Rack App (webhook receiver)
Workers
  AssetBuildingWorker
  SauceLabsWorker

Tasks TODO
==========
* **DONE** Implement Hooks for Asset Build (to be used by Travis not Github).
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
