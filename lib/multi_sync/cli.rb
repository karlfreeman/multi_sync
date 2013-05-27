require "thor"

module MultiSync

  # Defines constants and methods related to the CLI
  class Cli < Thor
    namespace :multi_sync

    class_option :verbose, :type => :boolean

    desc "sync", "Sync"
    method_option :credential, :aliases => "-c", :desc => "The fog credential to be used in this sync"
    method_option :clean, :aliases => "-C", :desc => "Clean up build files after sync"
    def sync
    end

  end

end