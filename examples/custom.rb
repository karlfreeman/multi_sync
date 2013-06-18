require "multi_sync"

MultiSync.configuration do |config|
  # config.target_pool_size = 16 # defaults to the amount of CPU core's your machine has
end

MultiSync.run do

  source :build {
    :type => :local, # :local is the source type, current options are :local
    :source_dir => "/path_to_your_build_folder",
    :targets => :www # an array of target names that this source should sync against
  }

  target :www {
    :type => :aws, # :aws is the target type's, current options are :aws
    :target_dir => "your_aws_bucket",
    :destination_dir => "an_optional_directory_inside_your_aws_bucket",
    :credentials => {
      :region => "us-east-1",
      :aws_access_key_id => "super_secret",
      :aws_secret_access_key => "super_secret"
    }
  }

end