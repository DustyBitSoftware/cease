require 'pathname'

require_relative 'report'

module Cease
  class CLI
    def initialize(argv: ARGV)
      @argv = argv
    end

    def execute
      report.execute
    end

    private

    attr_reader :argv

    def report
      Report.new(sources: sources)
    end

    def sources
      entries.each_with_object([]) do |given_path, paths|
        next unless given_path.exist?
        next if hidden_entry?(given_path)

        relevant_paths = []

        # Peform a depth-first search for a given Pathname.
        given_path.find do |path|
          relevant_paths << path if ruby_file?(path)
        end

        paths.concat(relevant_paths)
      end
    end

    def entries
      return Pathname.new('.').entries if argv.empty?
      argv.map { |arg| Pathname.new(arg) }
    end


    def hidden_entry?(path)
      path.basename.to_s.start_with? '.'
    end

    def ruby_file?(path)
      path.extname == '.rb'
    end
  end
end
