require './lib/cease/eviction/chunk'
require_relative '../../spec_helper'

RSpec.describe Cease::Eviction::Chunk do
  describe "#extract" do
    subject { described_class.new(ast: ast, statement: statement).extract }

    let(:parsed_ruby) { parse_ruby(source) }
    let(:ast) { parsed_ruby[0] }
    let(:comments) { parsed_ruby[1] }
    let(:statement) { Cease::Eviction::Statement.from_comments(*comments) }

    context 'with an eviction at the root ast' do
      let(:source) do
        <<-RUBY
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
        RUBY
      end

      it { is_expected.to eq(ast.children.compact) }
    end

    context 'with an eviction nested in a child node' do
      let(:source) do
        <<-RUBY
          module Test
            class TestClazz
              # [cease] at 6pm on 12/12/2021 { timezone: 'PST' }
              def initialize(*args)
                @one, @two, @three = args
              end
              # [/cease]

              def call_me
                puts 'Maybe'
              end
            end
          end
        RUBY
      end

      it 'includes children in the statement' do
        result = <<-RUBY
          def initialize(*args)
            @one, @two, @three = args
          end
        RUBY
        child = parse_ruby(result).flatten.first
        expect(subject).to include(child)
      end

      it 'excludes children outside the statement' do
        ignored = <<-RUBY
          def call_me
            puts 'Maybe'
          end
        RUBY
        ignored_child = parse_ruby(ignored).flatten.first
        expect(subject).to_not include(ignored_child)
      end
    end
  end
end
