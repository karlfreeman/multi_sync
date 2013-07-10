MultiSync.verbose = true

MultiSync.configuration do |config|
  config.verbose = true  # turn on verbose logging (defaults to false)
  # config.sync_outdated_files = true # when an outdated file is found whether to replace it (defaults to true)
  # config.delete_abandoned_files = true # when an abondoned file is found whether to remove it (defaults to true)
  # config.upload_missing_files = true # when a missing file is found whether to upload it (defaults to true)
  # config.target_pool_size = 16 # how many threads you would like to open for each target (defaults to the amount of CPU core's your machine has)
  # config.max_sync_attempts = 1 # how many times a file should be retried if there was an error during sync (defaults to 3)
end

MultiSync.prepare do

  source :public, {
    :type => :manifest,
    :source_dir => ::Rails.root.join("public", ::Rails.application.config.assets.prefix.sub(/^\//, "")),
    :targets => [ :www ]
  }

  target :www, {
    :type => :aws,
    :target_dir => "multi_sync",
    :credentials => {
      :region => "us-east-1",
      :aws_access_key_id => "AKIAJXMAC4YJEHPBYSHQ",
      :aws_secret_access_key => "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"
    }
  }

end