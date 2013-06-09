require "multi_sync"
require "awesome_print"

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

  source :local, "build", {
    :source_dir => "/tmp/build",
    :targets => [ :www ]
  }

end