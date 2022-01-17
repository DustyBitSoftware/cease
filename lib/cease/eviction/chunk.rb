require 'forwardable'

module Cease
  module Eviction
    class Chunk
      extend Forwardable

      # @params ast [Parser::AST::Node]
      # @params statement [Cease::Eviction::Statement]
      def initialize(ast:, statement:)
        @ast = ast
        @statement = statement
        @closest_parent = nil
        @children = []
      end

      # @return [Array<Parser::AST::Node>] 
      def extract
        return ast if only_child?

        find_closest_parent(ast)
        find_children(closest_parent)
        children
      end

      private

      attr_reader :ast, :closest_parent, :statement, :children

      delegate [:open_comment, :close_comment] => :statement

      # @note A depth-first search to find the closest non-comment parent to
      #   the open comment. The closest parent is found outside the boundaries
      #   of the Eviction statement.
      def find_closest_parent(ast)
        @closest_parent = ast

        return unless open_comment > ast

        filter_children(ast) do |child|
          # Skip the child if it begins past the closing comment.
          next if close_comment < child

          # Skip the child if the expression begins and ends on the same line
          # e.g. send, array, symbol
          next if open_comment > child && close_comment > child

          find_closest_parent(child)
        end
      end

      def find_children(ast)
        return children unless ast

        filter_children(ast) do |child|
          if open_comment > child && !close_comment.nested_in?(child)
            @children << child
            next # We got what we need. Don't go digging for other children.
          end

          find_children(child)
        end
      end

      def filter_children(ast)
        return unless block_given?

        ast.children.grep(Parser::AST::Node).each do |child|
          next unless child.respond_to? :loc
          next unless child.loc.expression

          yield(child)
        end
      end

      def only_child?
        ast.children.count < 2
      end
    end
  end
end
