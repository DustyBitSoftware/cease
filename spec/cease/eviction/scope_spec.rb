require './lib/cease/eviction/context'
require './lib/cease/eviction/scope'
require_relative '../../spec_helper'

RSpec.describe Cease::Eviction::Scope do
  it "is Forwardable" do
    expect(described_class).to be_a(Forwardable)
  end

  describe "#format" do
    subject do
      described_class.new(
        chunk: eviction_context.chunk,
        comments: eviction_context.comments,
        statement: eviction_context.statement
      ).format
    end

    let(:eviction_context) { from_source.first }
    let(:from_source) { Cease::Eviction::Context.from_source(source: source) }

    context "up to 24 lines" do
      let(:source) { Pathname.new('spec/samples/with_single_eviction.rb') } 
      it { is_expected.to contain_exactly(
        "module Test",
        "  class TestClazz",
        "    def initialize(*args)",
        "      @one, @two, @three = args",
        "    end",
        "",
        "    def call_me",
        "      puts 'Maybe'",
        "    end",
        "  end",
        "end"
      ) }
    end

    context "beyond 24 lines" do
      let(:source) { Pathname.new('spec/samples/with_large_chunk.rb') } 
      it { is_expected.to contain_exactly(
        "module Test",
        "  class TestClazz",
        "    class BadThing < StandardError; end",
        "",
        "    def initialize(*args)",
        "      @one, @two, @three = args",
        "    end",
        "",
        "    def call_me",
        "      puts 'Maybe'",
        "    end",
        "\n",
        "...18 line(s) truncated."
      ) }
    end
  end
end
