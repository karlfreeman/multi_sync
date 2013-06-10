# MultiSync ( WIP )

[Celluloid] based, [Fog::Storage] backed, asset synchronisation library

## Features / Usage Examples

```ruby
require "multi_sync"

MultiSync.configuration do |config|
  config.target_pool_size = 8 # for each target how many threads would you like to use? (defaults to the current systems CPU count)
  config.delete_abandoned_files = false # when an abondoned file is detected should we delete it? (defaults to false)
end

MultiSync.run do

  target :aws, :www, {
    :target_dir => "multi_sync",
    :destination_dir => "aws-target",
    :credentials => {
      :region => "us-east-1",
      :aws_access_key_id => "xxx",
      :aws_secret_access_key => "xxx"
    }
  }

  source :local, :build, {
    :source_dir => "/build",
    :targets => [ :www ] # must match each of the targets name's ( second paramater of target method )
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