require 'forwardable'

require 'rainbow'

module Cease
  class Summary
    extend Forwardable

    delegate [
      :source,
      :overdue_evictions
    ] => :examiner

    def initialize(examiner:)
      @examiner = examiner
    end

    def summarize
      return if overdue_evictions.none?

      puts Rainbow("(#{source_name})").underline.bright
      puts "\n#{overdue_evictions.map(&:description).join}"
    end

    private

    attr_reader :examiner

    def source_name
      source.to_s
    end
  end
end
