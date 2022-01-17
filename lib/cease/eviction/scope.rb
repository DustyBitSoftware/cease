require 'forwardable'

require 'rainbow'

module Cease
  module Eviction
    class Scope
      extend Forwardable

      # @params chunk [Cease::Eviction::Chunk]
      # @params comments [Array<Parser::Source::Comment>]
      # @params statement [Cease::Statement>]
      def initialize(chunk:, comments:, statement:)
        @chunk = chunk
        @comments = comments
        @statement = statement
      end

      # @return [Array<String>]
      def format
        length = formatted_lines.length

        case length
        when (0..25) then formatted_lines
        else
          [
            formatted_lines[0..10],
            formatted_lines[11] << "\n",
            Rainbow("...#{line_count - 12} line(s) truncated.").yellow
          ].flatten
        end
      end

      private

      attr_reader :chunk, :comments, :statement

      delegate [:open_comment, :close_comment] => :statement

      # @return [Array<Parser::AST::Node, Parser::Source::Comment>]
      def chunk_with_comments
        extracted_chunk = chunk.extract
        sorted_comments = comments.sort_by { |comment| comment.loc.line }

        sorted_scope = extracted_chunk.each_with_object([]) do |ast, results|
          until sorted_comments.first.loc.line > ast.loc.line do
            comment = sorted_comments.shift

            results << comment if comment.loc.line > open_comment.comment.loc.line
          end

          results << ast
        end

        # Concatenate any leftover comments outside AST nodes.
        sorted_comments.each do |comment|
          sorted_scope << comment if comment.loc.line < close_comment.comment.loc.line
        end

        sorted_scope
      end

      # @note Align indented lines relative to the expression's column.
      def formatted_lines
        @formatted_lines ||= chunk_with_comments.map do |content|
          column = content.loc.column

          # TODO: Find single line breaks between lines.
          content.loc.expression.source
            .split("\n")
            .map do |result|
              next result[column...] if result.start_with?(' ')
              result
            end
        end.flatten
      end

      def line_count
        statement.lines.inject(&:-).abs
      end
    end
  end
end
