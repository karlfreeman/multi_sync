# MultiSync

:heavy_exclamation_mark: **MultiSync is currently a functioning WIP its not finished yet but its close!** :heavy_exclamation_mark:

A flexible synchronisation library for your assets.

At MultiSync's core is [Celluloid](http://celluloid.io) allowing for the synchronisation of assets to be truly parallel. Each target you define creates a pool of resources which allows for parallel execution of uploads and deletes. Meaning that when your synchronising thousands of files, you get alot more :boom: for your :dollar:.

MultiSync tries to expose its asset synchronisation in a flexible way, allowing for it to be used in `Rails`, `Sinatra (WIP)`, `Rake (WIP)` and `Plain old ruby` as well as extensions for `Middleman (WIP)`, `Jekyll (WIP)`, `Nanoc (WIP)` and others. Listed below are examples of how to get setup.

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

`MultiSync` in its simplist form consists of three objects. `sources`, `resources` and `targets`. A `source` defines how and where a list of files (or `resources`) can be found. A `resource` represents a file from a `source` with addional properties (such as comparisons). A `target` is destination which `resources` can be synchronised against.

### Source

A source takes two arguments. The first is a `name` to reference this source by and the second is a `Hash` of configuration detailed below.

| Key | Type | Default | Description |
| :-- | :--- | :------ | :---------- |
| `type` | `Symbol` | `nil` | The `type` of source this is (`:local`, `:manifest`) |
| `source_dir` | `Pathname`, `String` | `nil` | The location this source should use |
| `resource_options` | `Hash` | `nil` | A hash of options for this source`s resources |
| `targets` | `Symbol`, `Array` | All targets | The target(s) this source should sync against |
| `include` | `String` ([shell glob](http://www.ruby-doc.org/core-2.1.1/Dir.html#method-c-glob)) | `**/*` | A shell globe to use for inclusion |
| `exclude` | `String` ([shell glob](http://www.ruby-doc.org/core-2.1.1/Dir.html#method-c-glob)) | `nil` | A shell globe to use for exclusion |
___

```ruby
# A source named ':build' which is ':local' and will use all files within '../build'
source :build, {
  type: :local,
  source_dir: '../build'
}
```
___

```ruby
# A source named ':assets' which will use a Sprockets ':manifest' within '../public/assets'
source :assets, {
  type: :manifest,
  source_dir: '../public/assets'
}
```
___

```ruby
# A source named ':video_assets' which is `:local' and will use all files
# within '../build' including only 'mp4, mpg, mov'
source :video_assets, {
  type: :local,
  source_dir: '../build',
  include: '*.{mp4,mpg,mov}'
}
```
___

```ruby
# A source named ':no_images' which is `:local' and will use all files
# within '../build' excluding any 'jpg, gif, png'
source :no_images, {
  type: :local,
  source_dir: '../build',
  exclude: '*.{jpg,gif,png}'
}
```
___

```ruby
# A source named ':www' which will use a Sprockets ':manifest'
# within '../public/assets' excluding any 'jpg, gif, png' files
# and only synchronising with a target named `:www`
source :www, {
  type: :manifest,
  source_dir: '../public/assets',
  exclude: '*.{jpg,gif,png}',
  targets: :www
}
```
___

```ruby
# A source named ':image_assets' which will use a Sprockets ':manifest'
# within '../public/assets' including only 'jpg, gif, png' files
# which sets `cache_control` and `expires` headers and
# synchronises with the target `:images`
source :image_assets, {
  type: :manifest,
  source_dir: '../public/assets',
  include: '*.{jpg,gif,png}',
  resource_options: {
    cache_control: 'public, max-age=31557600',
    expires: CGI.rfc1123_date(Time.now + 31557600)
  },
  targets: :images
}
```

### Target

```ruby
...
```


## Supported extensions

- [Rails](https://github.com/karlfreeman/multi_sync/wiki/rails)
- [Plain Old Ruby](https://github.com/karlfreeman/multi_sync/wiki/plain-old-ruby)
- Sinatra (WIP)
- Middleman (WIP)
- Jekyll (WIP)
- Nanoc (WIP)
- Rake (WIP)

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
