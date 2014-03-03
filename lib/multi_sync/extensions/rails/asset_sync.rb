module MultiSync
  module Extensions
    class AssetSync
      class << self
        def asset_sync_yml_exists?
          ::Rails.root.nil? ? false : File.exist?(asset_sync_yml_path)
        end

        def asset_sync_yml_path
          ::Rails.root.join('config', 'asset_sync.yml')
        end

        def asset_sync_yml
          @asset_sync_yml ||= YAML.load_file(asset_sync_yml_path)[MultiSync.env]
        end

        def check_and_migrate
          return unless self.asset_sync_yml_exists?
          MultiSync.info 'AssetSync YAML file found, migrating options...'

          MultiSync.source(:rails,
            type: :manifest,
            source_dir: MultiSync::Extensions::Rails.source_dir
          )

          MultiSync.target(:assets,
            type: asset_sync_yml['fog_provider'],
            target_dir: asset_sync_yml['fog_directory'],
            destination_dir: MultiSync::Extensions::Rails.destination_dir,
            credentials: {
              region: asset_sync_yml['region'],
              aws_access_key_id: asset_sync_yml['aws_access_key_id'],
              aws_secret_access_key: asset_sync_yml['aws_secret_access_key'],
              path_style: asset_sync_yml['path_style']
            }
          )

          MultiSync.delete_abandoned_files = asset_sync_yml['existing_remote_files'] == 'delete'
          MultiSync.run_on_build = asset_sync_yml['run_on_precompile']
        end
      end
    end
  end
end
