require 'parser/current'

require_relative 'chunk'
require_relative 'comment'
require_relative 'scope'
require_relative 'statement'

module Cease
  module Eviction
    class Context
      class << self
        # @params source [Pathname]
        #
        # @return [Array<Cease::Eviction>]
        def from_source(source:)
          source_to_chunks(source) do |chunk, statement, comments|
            new(comments: comments, statement: statement, chunk: chunk)
          end.compact
        end

        private

        def parsed_source(source)
          buffer = Parser::Source::Buffer.new(source.to_s, 1)
          buffer.read

          Parser::CurrentRuby.new.parse_with_comments(buffer)
        end

        def closest_close_comment(comments, index)
          # Find the next closest close command.
          # Nested evictions break things.
          comments[index..-1].find do |comment|
            Comment.close_comment?(comment)
          end
        end

        def source_to_chunks(source)
          ast, comments = parsed_source(source)

          comments.each_with_index.map do |comment, index|
            next if Comment.close_comment?(comment)

            statement = Statement.from_comments(
              comment,
              closest_close_comment(comments, index + 1),
              source
            )

            next unless statement.valid?

            chunk = Chunk.new(ast: ast, statement: statement)
            yield(chunk, statement, comments) if block_given?
          end
        end
      end

      def initialize(chunk:, comments:, statement:)
        @chunk = chunk 
        @comments = comments
        @statement = statement
      end

      def description
        indent = ' ' * 2
        lines_output = lines.inspect
        alignment = ' ' * (lines_output.length - indent.length)
        result = '' 

        header = "#{indent}#{Rainbow(lines_output).blue}: "\
          "#{Rainbow(statement.open_comment.past_due_description).indianred}\n"

        scope.format.each do |line|
          result << "#{alignment}#{line}\n"
        end

        "#{header}#{Rainbow(result).wheat}\n"
      end

      def lines
        return [] unless statement.valid?
        statement.lines
      end

      def overdue?
        return false unless statement.valid?
        statement.open_comment.overdue?
      end

      attr_reader :comments, :statement, :chunk

      private

      def scope
        @scope ||=
          Scope.new(chunk: chunk, comments: comments, statement: statement)
      end
    end
  end
end
