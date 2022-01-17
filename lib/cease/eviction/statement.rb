require_relative 'comment'

module Cease
  module Eviction
    class Statement
      def self.from_comments(*comments)
        open_comment, close_comment, source = comments

        new(
          open_comment: open_comment,
          close_comment: close_comment,
          source: source
        )
      end

      # @param open_comment [Parser::Source::Comment]
      # @param close_comment [Parser::Source::Comment]
      # @params source [Pathname]
      def initialize(open_comment:, close_comment:, source:)
        @open_comment = Comment.new(comment: open_comment, source: source)
        @close_comment = Comment.new(comment: close_comment, source: source)
      end

      def lines
        return [] unless valid?

        [open_comment, close_comment].map do |eviction_comment|
          eviction_comment.loc&.line
        end
      end

      def valid?
        [open_comment, close_comment].all?(&:valid?)
      end

      attr_reader :open_comment, :close_comment
    end
  end
end
