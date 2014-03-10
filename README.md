# MultiSync

:heavy_exclamation_mark: **currently a functioning WIP thats not quite finished yet but its close!** :heavy_exclamation_mark:

A flexible synchronisation library for your assets.

`MultiSync` stands on the shoulders of giants. On one side is [Celluloid](http://celluloid.io) allowing for the synchronisation of assets to be highly parallel. On the other is [Fog::Storage](https://github.com/fog/fog) allowing `MulitSync` to support [various well known storage services](#storage-services).

What that means is when your configuring `MultiSync` your creating various pools of workers which then distrubute the work behind synchronising your assets. Meaning that when your site has thousands of files, you get alot more :boom: for your :dollar: in less :alarm_clock:.

`MultiSync` tries to expose its asset synchronisation in a flexible way which should allow you to define how and where your assets live. Where possible though, `MultiSync` will try to provide support for [various well known libraries](#supported-libraries).

Listed below are examples of how to get setup and started.

## Installation

```ruby
gem 'multi_sync', '~> 0.0.2'
```

```ruby
require 'multi_sync'

MultiSync.configure do |config|
  # config.verbose = false  # turn on verbose logging (defaults to false)
  # config.force = false  # force syncing of outdated_files (defaults to false)
  # config.run_on_build = true # when within a framework which `builds` assets, whether to sync afterwards (defaults to true)
  # config.sync_outdated_files = true # when an outdated file is found whether to replace it (defaults to true)
  # config.delete_abandoned_files = true # when an abondoned file is found whether to remove it (defaults to true)
  # config.upload_missing_files = true # when a missing file is found whether to upload it (defaults to true)
  # config.target_pool_size = 8 # how many threads you would like to open for each target (defaults to the amount of CPU core's your machine has)
  # config.max_sync_attempts = 3 # how many times a file should be retried if there was an error during sync (defaults to 3)
end
```

### Fog credentials support

`MultiSync` supports utilising [Fog Credentials](http://fog.io/about/getting_started.html#credentials). Simply specify either a `FOG_RC` or `.fog` and we'll use it as the base for any `:credentials` used in a `target`.

## Features / Usage Examples

`MultiSync` in its simplist form consists of three objects. `sources`, `resources` and `targets`. A `source` defines how and where a list of files (or `resources`) can be found. A `resource` represents a file from a `source` with additional properties (such as how to compare them). A `target` is destination which `resources` can be synchronised against.

### Source

All `source`s takes one argument which is a `Hash` of configuration detailed below. There are currently two type's of `source`s which are

#### Source Types

- `local_source` - Uses all files within the `source_dir`
- `manifest_source` - Tries to find a `Sprocket`s `manifest.{yml,json}` file within the `source_dir`

| Key | Type | Default | Description |
| :-- | :--- | :------ | :---------- |
| `source_dir` | `Pathname`, `String` | `nil` | The location this `source` should use |
| `resource_options` | `Hash` | `{}` | A hash of options for this `source`'s resources |
| `targets` | `Symbol`, `Array` | All targets | The `target`(s) this `source` should sync against |
| `include` | `String` ([shell glob](http://www.ruby-doc.org/core-2.1.1/Dir.html#method-c-glob)) | `**/*` | A shell globe to use for inclusion |
| `exclude` | `String` ([shell glob](http://www.ruby-doc.org/core-2.1.1/Dir.html#method-c-glob)) | `nil` | A shell globe to use for exclusion |
___

```ruby
# A `local` `source` which will use all files within '../build'
local_source({
  source_dir: '../build'
})
```
___

```ruby
# A `manifest` `source` which will use a Sprockets ':manifest' within '../public/assets'
manifest_source({
  source_dir: '../public/assets'
})
```
___

```ruby
# A `local` `source` which will use all files
# within '../build' including only 'mp4, mpg, mov' files
local_source({
  source_dir: '../build',
  include: '*.{mp4,mpg,mov}'
})
```
___

```ruby
# A `local` `source` which will use all files
# within '../build' excluding any 'jpg, gif, png' files
local_source({
  source_dir: '../build',
  exclude: '*.{jpg,gif,png}'
})
```
___

```ruby
# A `manifest` `source` which will use use a Sprockets `manifest`
# within '../public/assets' including only 'jpg, gif, png' files
# which sets `cache_control` and `expires` headers
manifest_source({
  source_dir: '../public/assets',
  include: '*.{jpg,gif,png}',
  resource_options: {
    cache_control: 'public, max-age=31557600',
    expires: CGI.rfc1123_date(Time.now + 31557600)
  }
})
```

### Target

All `target`s takes one argument which is a `Hash` of configuration detailed below. There is currently only one `target` type which is:

#### Target Types

- `aws_target` - Synchronises to `aws` (`S3`)

| Key | Type | Default | Description |
| :-- | :--- | :------ | :---------- |
| `target_dir` | `Pathname`, `String` | `nil` | the name of the `target`'s directory (eg s3 bucket name) |
| `destination_dir` | `Pathname`, `String` | `nil` | the name of the `target` destination's directory (eg folder within target) |
| `credentials` | `Hash` | inherits [Fog Credentials](https://github.com/karlfreeman/multi_sync#fog-credentials-support) | credentionals needed by [Fog](http://fog.io) |
___

```ruby
# An `aws` `target` which will sync to the root of a bucket named 's3-bucket-name'
# with region, access_key_id, and secret_access_key specified
aws_target({
  target_dir: 's3-bucket-name'
  credentials: {
    region: 'us-east-1',
    aws_access_key_id: 'xxx',
    aws_secret_access_key: 'xxx'
  }
})
```
___

```ruby
# An `aws` `target` which will sync to a bucket named 's3-bucket-name'
# but within a directory named 'directory-within-s3'
# with region, access_key_id, and secret_access_key specified
aws_target({
  target_dir: 's3-bucket-name'
  destination_dir: 'directory-within-s3'
  credentials: {
    region: 'us-east-1',
    aws_access_key_id: 'xxx',
    aws_secret_access_key: 'xxx'
  }
})
```

## Supported Libraries

- [Rails](https://github.com/karlfreeman/multi_sync-rails)
- Sinatra (WIP)
- [Middleman](https://github.com/karlfreeman/multi_sync-middleman)
- Jekyll (WIP)
- Nanoc (WIP)

## Badges

[![Gem Version](http://img.shields.io/gem/v/multi_sync.svg)][gem]
[![Build Status](http://img.shields.io/travis/karlfreeman/multi_sync.svg)][travis]
[![Code Quality](http://img.shields.io/codeclimate/github/karlfreeman/multi_sync.svg)][codeclimate]
[![Gittip](http://img.shields.io/gittip/karlfreeman.svg)][gittip]

## Supported Storage Services

Behind the scenes we're using [Fog::Storage](http://fog.io/storage) which allows us to support the most popular storage providers

- [Amazon S3](http://aws.amazon.com/s3)
- [Rackspace CloudFiles](http://www.rackspace.com/cloud/files) (WIP)
- [Google Cloud Storage](https://developers.google.com/storage) (WIP)

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
