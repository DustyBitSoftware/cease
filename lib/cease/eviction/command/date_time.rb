require 'forwardable'
require 'yaml'

require_relative '../../git'

module Cease
  module Eviction
    module Command
      class DateTime
        extend Forwardable

        class BadOptionsError < StandardError; end

        DEFAULT_TIMEZONE = 'UTC'.freeze
        TIMEZONE_NAME_MAPPING = {
          "UTC" => "Etc/UTC",
          "PST" => "America/Los_Angeles",
          "MTZ" => "America/Denver",
          "CST" => "America/Chicago",
          "EST" => "America/New_York"
        }.freeze
        TIMEZONE_KEY = "timezone".freeze

        # @params comment [Cease::Eviction::Comment]
        # @params date_time [String]
        # @params options [String]
        def initialize(comment, date_time, options)
          @comment = comment
          @time, @date = parse(date_time)
          @options = options
        end

        # @return [TZ::DateTimeWithOffset, nil]
        def parsed_in_timezone
          return unless valid?
          tz.local_datetime(*local_datetime_args)
        end

        def valid?
          return false unless valid_time?
          return false if date && !valid_date?
          return false if timezone_name && !valid_timezone?
          true
        rescue
          false
        end

        def guess?
          return true unless parsed_date
          !!parsed_date
        rescue
          true
        end

        def tz
          ::TZInfo::Timezone.get(
            TIMEZONE_NAME_MAPPING[timezone_name] ||
            TIMEZONE_NAME_MAPPING[DEFAULT_TIMEZONE]
          )
        end

        private

        delegate [:year, :month, :day, :hour, :minute] => :best_guess_date

        attr_reader :comment, :options, :time, :date
        
        def parse(date_time)
          split = date_time.split(' ')
          results = []

          loop do
            break if split.length == 0
            results << split.shift(2)
          end

          results
            .partition { |result| result.include?("at") }
            .map { |result| _identifer, value = result.flatten; value }
        end

        def parsed_options
          @parsed_options ||= YAML.safe_load(options || '')
        rescue Psych::SyntaxError
          raise BadOptionsError
        end

        def timezone_name
          return unless parsed_options
          parsed_options[TIMEZONE_KEY]
        end

        def valid_time?
          return false unless time
          parsed_time
        end

        def valid_date?
          return false unless date
          parsed_date
        end

        def valid_timezone?
          return true if TIMEZONE_NAME_MAPPING.keys.include?(timezone_name)
          false
        end

        def best_guess_date
          @best_guess_date ||= begin
            parsed_date ||
            (comment.last_commit_date &&
              ::DateTime.parse(comment.last_commit_date.to_s)) ||
            ::DateTime.now
          end
        end

        def local_datetime_args
          [year, month, day, hour, minute]
        end

        def parsed_date
          return unless date

          ::DateTime.strptime(
            "#{date} #{parsed_time.hour}:#{parsed_time.minute}",
            "%m/%d/%Y %H:%M"
          )
        end

        def parsed_time
          @parsed_time ||= ::DateTime.parse(time)
        end
      end
    end
  end
end
