require_relative 'summary'
require_relative 'eviction/context'

module Cease
  class Examiner
    # @param source [Pathname]
    def initialize(source:)
      @source = source
    end

    def evictions
      @evictions ||= Eviction::Context.from_source(source: source)
    end

    def summarize
      return unless summarizable?
      Summary.new(examiner: self).summarize
    end

    def summarizable?
      overdue_evictions.any?
    end

    def overdue_evictions
      evictions.select(&:overdue?)
    end

    attr_reader :source
  end
end
