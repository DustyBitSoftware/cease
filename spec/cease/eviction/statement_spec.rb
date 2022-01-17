require './lib/cease/eviction/statement'
require_relative '../../spec_helper'

RSpec.describe Cease::Eviction::Statement do
  let(:open_comment) { comments[0] }
  let(:close_comment) { comments[1] }
  let(:comments) { parsed_ruby[1] }

  let(:parsed_ruby) { parse_ruby(ruby_source) }
  let(:ruby_source) do
    <<-RUBY
      require 'other_module'

      # [cease] at 6pm on 12/12/2021 { timezone: 'PST' }
      module Test; end
      # [/cease]
    RUBY
  end
  let(:source_double) { instance_double(Pathname) }

  describe '.from_comments' do
    subject do
      described_class.from_comments(
        open_comment,
        close_comment,
        source_double
      )
    end

    it 'returns a new instance of the class' do
      expect(described_class).to receive(:new).
        with(
          open_comment: open_comment,
          close_comment: close_comment,
          source: source_double
        )
      subject
    end
  end

  describe '#lines' do
    subject { instance.lines }
    
    let(:instance) do
      described_class.new(
        open_comment: open_comment,
        close_comment: close_comment,
        source: source_double
      )
    end

    context "with an invalid comment" do
      before do
        allow(instance.open_comment).to receive(:valid?).and_return(false)
      end

      it { is_expected.to eq([]) }
    end

    context "when both comments are valid" do
      it { is_expected.to eq([3, 5]) }
    end
  end
end
