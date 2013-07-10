require "multi_sync"

MultiSync.configuration do |config|
  config.verbose = true  # turn on verbose logging (defaults to false)
  # config.sync_outdated_files = true # when an outdated file is found whether to replace it (defaults to true)
  # config.delete_abandoned_files = true # when an abondoned file is found whether to remove it (defaults to true)
  # config.upload_missing_files = true # when a missing file is found whether to upload it (defaults to true)
  # config.target_pool_size = 16 # how many threads you would like to open for each target (defaults to the amount of CPU core's your machine has)
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