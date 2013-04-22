require "thor"

module MultiSync

  class Cli < Thor
    namespace :multi_sync

    class_option :verbose, :type => :boolean
    class_option :remote_files_policy, :type => :boolean

    desc "sync", "a description"
    method_option :clean, :aliases => "-c", :desc => "Clean up build files after sync"
    def sync
    end

  end
end