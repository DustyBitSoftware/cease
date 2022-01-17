require 'forwardable'
require 'dotiw'

require_relative 'command/date_time'

module Cease
  module Eviction
    class Comment
      extend Forwardable

      include Comparable
      include DOTIW::Methods

      # @examples
      #   [cease] at 14:00
      #   [cease] at 1pm on 01/01/2044
      #   [cease] at 2:30pm on 12/01/2021 {timezone: 'PST'}
      OPEN_COMMENT_REGEX = /
        \[cease\]\s # prefix
        (.+?) # non-greedy date and time
        (:?\s*) # optional seperator
        (\{.*?\})? # optional options
        $ # extend non-greedy matchers to end of line
      /x.freeze
      CLOSE_COMMENT_REGEX = /\[\/cease\]/.freeze

      def self.close_comment?(comment)
        return false unless comment
        !!(comment.text =~ CLOSE_COMMENT_REGEX)
      end

      # @params comment [Parser::Source::Comment]
      # @params source [Pathname]
      def initialize(comment:, source: nil)
        @comment = comment
        @date_time, @seperator, @options = scanned_comment
        @source = source
      end

      def parse
        scanned_comment
      end

      def date_time
         Command::DateTime.new(self, @date_time, @options)
      end

      def close_comment?
        self.class.close_comment?(comment)
      end

      def last_commit_date
        return unless source

        line = loc.line
        search = "-L #{line},#{line}:#{source.to_s}"
        Git.log.object(search)&.first&.date
      end

      def past_due_description
        return unless overdue?

        dotiw = distance_of_time_in_words(
          date_time.tz.to_local(DateTime.now),
          date_time.parsed_in_timezone,
          highest_measures: 1
        )

        "Overdue by roughly #{dotiw}"
      end

      def overdue?
        return false if close_comment?
        return false unless date_time.valid?

        date_time.tz.to_local(DateTime.now) >= date_time.parsed_in_timezone
      end

      def <=>(other)
        other.loc.expression.begin_pos <=> loc.expression.begin_pos
      end

      def nested_in?(other)
        other.loc.expression.end_pos > loc.expression.begin_pos
      end

      def valid?
        return false unless comment
        return true if close_comment?
        parse.any?
      end

      attr_reader :comment, :options, :source

      private

      delegate loc: :comment

      def scanned_comment
        return [] unless comment

        @scanned_comment ||=
          comment.text.scan(OPEN_COMMENT_REGEX).flatten
      end
    end
  end
end
