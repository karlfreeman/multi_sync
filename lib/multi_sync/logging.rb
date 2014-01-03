require 'logger'

module MultiSync
  module Logging

    MUTEX = Mutex.new

    def logger
      @logger || initialize_logger
    end

    def logger=(new_logger)
      @logger = new_logger ? new_logger : Logger.new('/dev/null')
    end

    def status_logger
      @status_logger || initialize_status_logger
    end

    def status_logger=(new_status_logger)
      @status_logger = new_status_logger ? new_status_logger : nil
    end

    def say_status(status, message, log_status = true)

      return if status_logger.nil?

      if defined?(Thor) && status_logger.is_a?(Thor)
        MUTEX.synchronize do
          status_logger.say_status status, message, log_status
        end
      end

    end

    def log(message, level = :debug)

      # We're in verbose mode so disable all non-info logs
      return if !MultiSync.verbose && level != :info

      MUTEX.synchronize do
        logger.send(level, message)
      end

    end

    # Create methods for the different shorthand log methods
    [:info, :debug, :warn, :error].each do |log_method|
      # Shorthand log method
      define_method log_method do |message|
        send(:log, message, log_method)
      end
    end

    private

    # Configure default logger
    def initialize_logger
      @logger = ::Logger.new(STDOUT)
    end

    def initialize_status_logger
      @status_logger = nil
    end


  end

end
