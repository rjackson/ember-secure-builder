require 'bundler/setup'

require 'dotenv'
Dotenv.load

require 'ember-secure-builder/rack_app'
require 'ember-secure-builder/workers/asset_building_worker'
