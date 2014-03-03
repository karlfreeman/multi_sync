# MultiSync

:heavy_exclamation_mark: **a WIP that is functioning but just a warning, not finished yet.** :heavy_exclamation_mark:

Asset synchronisation library

At MultiSync's core is [Celluloid](http://celluloid.io) allowing for the synchronisation of assets to be truly parallel. Each target you define creates a pool of resources which allows for parallel execution of uploads and deletes. Meaning that when your synchronising thousands of files, you get alot more :boom: for your :dollar:.

MultiSync tries to expose its asset synchronisation in a flexible way, allowing for it to be used in `Rails`, `Sinatra (WIP)`, `Rake (WIP)` and `Plain old ruby` as well as extensions for `Middleman (WIP)`, `Nanoc (WIP)` and others. Listed below are examples of how to get setup.

## Installation

```ruby
gem 'multi_sync', '~> 0.0.1'
```

```ruby
require 'multi_sync'

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
```

### Fog credentials support

`MultiSync` supports utilising [Fog Credentials](http://fog.io/about/getting_started.html#credentials). Simply specify either a `FOG_RC` or `.fog` and we'll use it as the base for any credentials used in a target.

## Features / Usage Examples

### AssetSync compatibility

Many people use [AssetSync](https://github.com/rumblelabs/asset_sync) and for `MultiSync`'s first release compatibility with it has been built in. When within a `Rails` environment `MultiSync` will check for `asset_sync.yml` and read in its settings. You should be able to simply require `multi_sync` and try things out.

#### Unsupported features

- `AssetSync`'s environment variables
- `AssetSync`'s gzip_compression hack

### Rails

`MultiSync` prefers ruby backed configuration instead of `YAML` so you'll need to create an initializer `/config/initializers/multi_sync` for `MultiSync`.

```ruby
MultiSync.prepare do

  source :public, {
    type: :manifest, # load files from a Sprockets based manifest
    source_dir: '/path_to_your_build_folder',
    targets: [:assets] # an array of target names that this source should sync against
  }

  target :assets, {
    type: :aws, # :aws is the target's type, current options are :aws
    target_dir: 'your_aws_bucket',
    destination_dir: 'an_optional_directory_inside_your_aws_bucket',
    credentials: {
      region: 'us-east-1',
      aws_access_key_id: 'super_secret',
      aws_secret_access_key: 'super_secret'
    }
  }

end
```

`MultiSync.prepare` simply bootstraps `MultiSync` which is then ran during `rake assets:precompile`. By having `multi_sync` included in your `Gemfile`, the rake task `rake assets:sync` will be available. Paired with turning `MultiSync.run_on_build` off will allow you to sync on your terms.

### Plain Old Ruby

```ruby
MultiSync.run do

  source :build, {
    type: :local, # :local is the source's type, current options are :local, :manifest
    source_dir: '/path_to_your_build_folder',
    targets: [:assets] # an array of target names that this source should sync against
  }

  target :assets, {
    type: :aws, # :aws is the target's type, current options are :aws
    target_dir: 'your_aws_bucket',
    destination_dir: 'an_optional_directory_inside_your_aws_bucket',
    credentials: {
      region: 'us-east-1',
      aws_access_key_id: 'super_secret',
      aws_secret_access_key: 'super_secret'
    }
  }

end
```

## Badges

[![Gem Version](http://img.shields.io/gem/v/multi_sync.svg)][gem]
[![Build Status](http://img.shields.io/travis/karlfreeman/multi_sync.svg)][travis]
[![Code Quality](http://img.shields.io/codeclimate/github/karlfreeman/multi_sync.svg)][codeclimate]
[![Gittip](http://img.shields.io/gittip/karlfreeman.svg)][gittip]

## Supported Storage Services

Behind the scenes we're using [Fog::Storage](http://fog.io/storage) which allows us to support the most popular storage providers

- [Amazon S3](http://aws.amazon.com/s3)
- [Rackspace CloudFiles](http://www.rackspace.com/cloud/files)
- [Google Cloud Storage](https://developers.google.com/storage)

## Supported Ruby Versions

This library aims to support and is [tested against][travis] the following Ruby
implementations:

- Ruby 2.1.0
- Ruby 2.0.0
- Ruby 1.9.3
- [JRuby][jruby]
- [Rubinius][rubinius]

# Credits

[gem]: https://rubygems.org/gems/multi_sync
[travis]: http://travis-ci.org/karlfreeman/multi_sync
[codeclimate]: https://codeclimate.com/github/karlfreeman/multi_sync
[gittip]: https://www.gittip.com/karlfreeman
[jruby]: http://www.jruby.org
[rubinius]: http://rubini.us
