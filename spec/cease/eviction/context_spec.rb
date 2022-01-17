require './lib/cease/eviction/context'
require_relative '../../spec_helper'

RSpec.describe Cease::Eviction::Context do
  describe '.from_source' do
    subject { described_class.from_source(source: source) }

    context "with a source without evictions" do
      let(:source) { Pathname.new('spec/samples/without_evictions.rb') } 
      it { is_expected.to be_empty }
    end

    context "with a source containing a single eviction" do
      let(:source) { Pathname.new('spec/samples/with_single_eviction.rb') } 
      let(:context_double) { instance_double(Cease::Eviction::Context) }

      before do
        allow(Cease::Eviction::Context).to receive(:new)
          .and_return(context_double)
      end

      it { is_expected.to contain_exactly(context_double) }
    end

    context "with a source containing multiple evictions" do
      let(:source) { Pathname.new('spec/samples/with_multiple_evictions.rb') } 

      let(:context_double_1) { instance_double(Cease::Eviction::Context) }
      let(:context_double_2) { instance_double(Cease::Eviction::Context) }

      before do
        allow(Cease::Eviction::Context).to receive(:new)
          .and_return(context_double_1, context_double_2)
      end

      it { is_expected.to contain_exactly(context_double_1, context_double_2) }
    end
  end

  describe '#description' do
    subject { from_source.first.description }

    let(:from_source) { described_class.from_source(source: source) }
    let(:source) { Pathname.new('spec/samples/with_single_eviction.rb') } 

    it { is_expected.to eq(
      "  [3, 15]: Overdue by roughly 1 month\n" \
      "     module Test\n       class TestClazz\n       " \
      "  def initialize(*args)\n           @one, @two, @three = args\n     " \
      "    end\n     \n         def call_me\n           puts 'Maybe'\n     " \
      "    end\n       end\n     end\n\n"
    ) }
  end

  describe "#lines" do
    subject { eviction_context.lines }

    let(:eviction_context) { from_source.first }
    let(:from_source) { described_class.from_source(source: source) }
    let(:source) { Pathname.new('spec/samples/with_single_eviction.rb') } 

    context "with an invalid eviction statement" do
      let(:statement_double) do
        instance_double(Cease::Eviction::Statement, valid?: false)
      end

      before do
        allow(eviction_context).to receive(:statement)
          .and_return(statement_double)
      end

      it { is_expected.to eq([]) }
    end

    context "with a valid eviction statement" do
      it { is_expected.to eq([3, 15]) }
    end
  end

  describe "#overdue?" do
    subject { eviction_context.overdue? }

    let(:eviction_context) { from_source.first }
    let(:from_source) { described_class.from_source(source: source) }
    let(:source) { Pathname.new('spec/samples/with_single_eviction.rb') } 

    context "with an invalid eviction statement" do
      let(:statement_double) do
        instance_double(Cease::Eviction::Statement, valid?: false)
      end

      before do
        allow(eviction_context).to receive(:statement)
          .and_return(statement_double)
      end

      it { is_expected.to eq(false) }
    end

    context "with a valid eviction statement" do
      context "when the eviction is overdue" do
        it { is_expected.to eq(true) }
      end

      context "when the eviction is not overdue" do
        let(:source) { Pathname.new('spec/samples/with_multiple_evictions.rb') } 
        it { is_expected.to eq(false) }
      end
    end
  end
end
