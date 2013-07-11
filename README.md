# MultiSync ( WIP )

[Celluloid] based, [Fog::Storage] backed, asset synchronisation library

## Features / Usage Examples

```ruby
require "multi_sync"

MultiSync.configuration do |config|
  # config.verbose = false  # turn on verbose logging (defaults to false)
  # config.force = false  # force syncing of outdated_files (defaults to false)
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
    :targets => [ :www ] # an array of target names that this source should sync against
  }

  target :www {
    :type => :aws, # :aws is the target's type, current options are :aws
    :target_dir => "your_aws_bucket",
    :destination_dir => "an_optional_directory_inside_your_aws_bucket",
    :credentials => {
      :region => "us-east-1",
      :aws_access_key_id => "super_secret",
      :aws_secret_access_key => "super_secret"
    }
  }

end

```

## Build & Dependency Status

[![Gem Version](https://badge.fury.io/rb/multi_sync.png)][gem]
[![Build Status](https://travis-ci.org/karlfreeman/multi_sync.png)][travis]
[![Dependency Status](https://gemnasium.com/karlfreeman/multi_sync.png?travis)][gemnasium]
[![Code Quality](https://codeclimate.com/github/karlfreeman/multi_sync.png)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/karlfreeman/multi_sync/badge.png?branch=master)][coveralls]

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