# MultiSync (WIP)

Asset synchronisation library

## Features / Usage Examples

At MultiSync's core is [Celluloid] allowing for the synchronisation of assets to be truly parallel. Each target you define creates a pool of resources which allows for parallel execution of uploads and deletes. Meaning that when your uploading thousands of files, you get alot more bang for your buck.

MultiSync tries to expose its asset synchronisation in a flexible way, allowing for it to be used in `Rails (WIP)`, `Sinatra (WIP)`, `Rake (WIP)` and `Plain old ruby (WIP)` as well as extensions for `Middleman (WIP)`, `Nanoc (WIP)` and others too. Listed below are examples of how to get setup.

### POR (WIP)

```ruby
gem "multi_sync", "~> 0.0.1"
```

```ruby
require "multi_sync"

MultiSync.configuration do |config|
  # config.verbose = false  # turn on verbose logging (defaults to false)
  # config.force = false  # force syncing of outdated_files (defaults to false)
  # config.run_on_build = true # when within a framework which `builds` assets, whether to sync afterwards (defaults to true)
  # config.sync_outdated_files = true # when an outdated file is found whether to replace it (defaults to true)
  # config.delete_abandoned_files = true # when an abondoned file is found whether to remove it (defaults to true)
  # config.upload_missing_files = true # when a missing file is found whether to upload it (defaults to true)
  # config.target_pool_size = 8 # how many threads you would like to open for each target (defaults to the amount of CPU core's your machine has)
  # config.max_sync_attempts = 1 # how many times a file should be retried if there was an error during sync (defaults to 3)
end

MultiSync.run do

  source :build {
    :type => :local, # :local is the source's type, current options are :local, :manifest
    :source_dir => "/path_to_your_build_folder",
    :targets => [ :assets ] # an array of target names that this source should sync against
  }

  target :assets {
    :type => :aws, # :aws is the target's type, current options are :aws
    :target_dir => "your_aws_bucket", # 
    :destination_dir => "an_optional_directory_inside_your_aws_bucket", # 
    :credentials => {
      :region => "us-east-1",
      :aws_access_key_id => "super_secret",
      :aws_secret_access_key => "super_secret"
    }
  }

end

```

### Rails

```ruby
gem "multi_sync", "~> 0.0.1"
```

in `/config/initializers/multi_sync`
```ruby
MultiSync.configure do |config|
  # config.verbose = false  # turn on verbose logging (defaults to false)
  # config.force = false  # force syncing of outdated_files (defaults to false)
  # config.run_on_build = true # when within a framework which `builds` assets, whether to sync afterwards (defaults to true)
  # config.sync_outdated_files = true # when an outdated file is found whether to replace it (defaults to true)
  # config.delete_abandoned_files = true # when an abondoned file is found whether to remove it (defaults to true)
  # config.upload_missing_files = true # when a missing file is found whether to upload it (defaults to true)
  # config.target_pool_size = 8 # how many threads you would like to open for each target (defaults to the amount of CPU core's your machine has)
  # config.max_sync_attempts = 1 # how many times a file should be retried if there was an error during sync (defaults to 3)
end

MultiSync.prepare do

  source :public, {
    :type => :manifest,
    :source_dir => ::Rails.root.join("public", ::Rails.application.config.assets.prefix.sub(/^\//, "")), # hopefully will abstract away
    :targets => [:assets]
  }

  target :assets, {
    :type => :aws,
    :target_dir => "your_aws_bucket",
    :credentials => {
      :region => "us-east-1",
      :aws_access_key_id => "super_secret",
      :aws_secret_access_key => "super_secret"
    }
  }

end

```

which will run `MultiSync.run` after `rake assets:precompile`

By having `multi_sync` included in your `Gemfile`, the rake task `rake assets:sync` will be available. Paired with turning `MultiSync.run_on_build` off will allow you to sync on your terms.

### Sinatra (WIP)

### Rake (WIP)

## Build & Dependency Status

[![Gem Version](https://badge.fury.io/rb/multi_sync.png)][gem]
[![Build Status](https://travis-ci.org/karlfreeman/multi_sync.png)][travis]
[![Dependency Status](https://gemnasium.com/karlfreeman/multi_sync.png?travis)][gemnasium]
[![Code Quality](https://codeclimate.com/github/karlfreeman/multi_sync.png)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/karlfreeman/multi_sync/badge.png?branch=master)][coveralls]

## Supported services

## Supported Ruby Versions
This library aims to support and is [tested against][travis] the following Ruby
implementations:

* Ruby 1.9.2
* Ruby 1.9.3
* Ruby 2.0.0
* [JRuby][]
* [Rubinius][]

# Credits

[celluloid]: http://celluloid.io
[fog::storage]: http://fog.io/storage
[gem]: https://rubygems.org/gems/multi_sync
[travis]: http://travis-ci.org/karlfreeman/multi_sync
[gemnasium]: https://gemnasium.com/karlfreeman/multi_sync
[coveralls]: https://coveralls.io/r/karlfreeman/multi_sync
[codeclimate]: https://codeclimate.com/github/karlfreeman/multi_sync
[jruby]: http://www.jruby.org
[rubinius]: http://rubini.us