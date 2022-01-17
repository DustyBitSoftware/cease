module Helpers
  def parse_ruby(source)
    buffer = Parser::Source::Buffer.new("not_important.rb", 1)
    buffer.source = source
    Parser::CurrentRuby.new.parse_with_comments(buffer)
  end
end

Rainbow.enabled = false

RSpec.configure do |config|
  config.include Helpers
end 
