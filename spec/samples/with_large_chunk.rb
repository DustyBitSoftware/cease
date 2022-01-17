require 'this'

# [cease] at 6pm on 12/12/2021 { timezone: 'PST' }
module Test
  class TestClazz
    class BadThing < StandardError; end

    def initialize(*args)
      @one, @two, @three = args
    end

    def call_me
      puts 'Maybe'
    end

    private

    def hello
      puts 'good morning'
    end

    def good_bye
      puts 'farewell'
    end
  end

  module NestedModule
    def module_method
      true
    end
  end
end
# [/cease]
