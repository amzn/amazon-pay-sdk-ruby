# rubocop:disable Metrics/MethodLength

require 'logger'
require 'stringio'

module AmazonPay
  # This class creates the logger to use.
  class LogInitializer
    def initialize(
      log_file_name,
      log_level
    )

      @log_level_set = log_hash[log_level.upcase]
      @log_file_name = log_file_name
    end

    def create_logger
      @logger = if @log_file_name
                  Logger.new(@log_file_name)
                else
                  Logger.new(STDOUT)
                end

      @logger.level = @log_level_set
      # a simple formatter
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S'
      # e.g. "2004-01-03 00:54:26"
      @logger.formatter = proc do |_severity, datetime, progname, msg|
        %({time: "#{datetime}\n", message: "#{msg} from #{progname}"}\n)
      end

      @logger
    end

    private

    def log_hash
      {
        UNKNOWN: Logger::UNKNOWN,
        FATAL: Logger::FATAL,
        ERROR: Logger::ERROR,
        WARN: Logger::WARN,
        INFO: Logger::INFO,
        DEBUG: Logger::DEBUG
      }
    end
  end
end
