require 'other_module'

# [cease] at 6pm on 12/12/2021 { timezone: 'PST' }
module Test
  class TestClazz
    def initialize(*args)
      @one, @two, @three = args
    end

    def call_me
      puts 'Maybe'
    end
  end
end
# [/cease]
