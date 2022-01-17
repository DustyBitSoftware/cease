require_relative 'examiner'

module Cease
  class Report
    SUCCESS_EXIT_CODE = 0
    ERROR_EXIT_CODE = 1

    def initialize(sources:)
      @sources = sources
      @examiners = []
      @total_eviction_count = 0
    end

    def execute
      print_header

      sources.each do |source|
        add_examiner(Examiner.new(source: source))
      end

      print_results
      print_footer if reportable?

      result_code
    end

    attr_accessor :total_eviction_count

    private

    attr_reader :examiners, :sources

    def add_examiner(examiner)
      self.total_eviction_count += examiner.overdue_evictions.length
      examiners << examiner
    end

    def print_results
      summarizable_examiners.each(&:summarize)
    end

    def print_header
      puts "\nScanning #{sources.length} source(s)...\n\n"
    end

    def print_footer
      puts Rainbow(
        Rainbow"\nTotal of #{total_eviction_count} evictions(s) found.\n"
      ).green
    end

    def result_code
      if reportable?
        ERROR_EXIT_CODE
      else
        SUCCESS_EXIT_CODE
      end
    end

    def reportable?
      summarizable_examiners.any?
    end

    def summarizable_examiners
      examiners.select(&:summarizable?)
    end
  end
end
