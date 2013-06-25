require "logger"

module MultiSync

  # Defines constants and methods related to the logging
  module Logging

    #
    def logger
      @logger || initialize_logger
    end

    #
    def logger=(new_logger)
      @logger = (new_logger ? new_logger : Logger.new("/dev/null"))
    end

    #
    def log(message, level = :debug)

      # We're in verbose mode so disable all non-info logs
      return if !MultiSync.verbose && level != :info

      # If the message has multiple lines, lets print them
      if message.respond_to? :each_line
        message.each_line { |line| logger.send level, line.chomp }
      else
        logger.send(level, message)
      end

    end

    # Create methods for the different shorthand log methods
    [:info, :debug, :warn, :error].each do |log_method|
      # Shorthand log method
      define_method log_method do |message|
        self.send(:log, message, log_method)
      end
    end

    private

    # Configure default logger
    def initialize_logger
      @logger = ::Logger.new(STDOUT)
    end


  end

end