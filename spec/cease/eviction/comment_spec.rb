require './lib/cease/eviction/comment'
require_relative '../../spec_helper'

RSpec.describe Cease::Eviction::Comment do
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

  it "extends forwardable" do
    expect(described_class).to be_a(Forwardable)
  end

  it "includes comparable" do
    expect(described_class.ancestors).to include(Comparable)
  end

  it "includes DOTIW methods" do
    expect(described_class.ancestors).to include(DOTIW::Methods)
  end

  describe ".close_comment?" do
    subject { described_class.close_comment?(comment) }

    context "without a comment" do
      let(:comment) { nil }
      it { is_expected.to eq(false) }
    end

    context "with an open comment" do
      let(:comment) { open_comment }
      it { is_expected.to eq(false) }
    end

    context "with a close comment" do
      let(:comment) { close_comment }
      it { is_expected.to eq(true) }
    end
  end

  describe "#parse" do
    subject { described_class.new(comment: comment).parse }

    context "without a comment" do
      let(:comment) { nil }
      it { is_expected.to be_empty } 
    end

    context "with an open comment" do
      let(:comment) { open_comment }

      it "returns the parsed results" do
        expect(subject).to contain_exactly(
          "at 6pm on 12/12/2021",
          " ",
          "{ timezone: 'PST' }"
        )
      end
    end

    context "with a close comment" do
      let(:comment) { close_comment }
      it { is_expected.to be_empty } 
    end
  end

  describe "#date_time" do
    subject { described_class.new(comment: comment).date_time }

    let(:comment) { open_comment }

    it "returns a new date time object" do
      expect(subject).to be_a(Cease::Eviction::Command::DateTime)
    end
  end

  describe "#close_comment?" do
    subject { described_class.new(comment: comment).close_comment? }

    context "without a comment" do
      let(:comment) { nil }
      it { is_expected.to eq(false) }
    end

    context "with an open comment" do
      let(:comment) { open_comment }
      it { is_expected.to eq(false) }
    end

    context "with a close comment" do
      let(:comment) { close_comment }
      it { is_expected.to eq(true) }
    end
  end

  describe "#last_commit_date" do
    subject do
      described_class.new(comment: comment, source: source).last_commit_date
    end

    let(:comment) { open_comment }

    context "without a source" do
      let(:source) { nil }
      it { is_expected.to eq(nil) }
    end

    context "with a source" do
      let(:source) { Pathname.new('source.rb') }
      let(:git_log_double) do
        instance_double(Git::Log)
      end

      before do
        allow(Cease::Git).to receive(:log)
          .and_return(git_log_double)
      end

      context "when a Git object does not exist" do
        before do
          allow(git_log_double).to receive(:object)
            .with("-L 3,3:source.rb").and_return([])
        end

        it { is_expected.to eq(nil) }
      end

      context "when a Git object exists" do
        let(:git_search_log_double) do
          instance_double(Git::Log, first: git_object_double)
        end
        let(:git_object_double) do
          instance_double(Git::Object::Commit, date: date)
        end
        let(:date) { Time.parse("1999-01-01") }

        before do
          allow(git_log_double).to receive(:object)
            .with("-L 3,3:source.rb").and_return(git_search_log_double)
        end

        it "returns the last commit date of the line" do
          expect(subject).to eq(date)
        end
      end
    end
  end

  describe "#past_due_description" do
    subject { instance.past_due_description }

    let(:instance) { described_class.new(comment: comment) }

    context "with an open comment" do
      let(:comment) { open_comment }

      context "the eviction is overdue" do
        let(:date_time_double) do
          instance_double(
            Cease::Eviction::Command::DateTime,
            tz: tz_double,
            parsed_in_timezone: instance.date_time.parsed_in_timezone,
            valid?: true
          )
        end
        let(:tz_double) do
          instance_double(
            TZInfo::DataTimezone,
            to_local: DateTime.parse('2022-01-01')
          )
        end

        before do
          allow(instance).to receive(:date_time)
            .and_return(date_time_double)
        end

        it { is_expected.to eq("Overdue by roughly 2 weeks") }
      end

      context "the eviction is not overdue" do
        before do
          allow(instance).to receive(:overdue?).and_return(false)
        end

        it { is_expected.to eq(nil) }
      end
    end

    context "with a close comment" do
      let(:comment) { close_comment }
      it { is_expected.to eq(nil) }
    end
  end

  describe "#overdue?" do
    subject { instance.overdue? }

    let(:instance) { described_class.new(comment: comment) }

    context "with a close comment" do
      let(:comment) { close_comment }
      it { is_expected.to eq(false) }
    end

    context "with an open comment" do
      let(:comment) { open_comment }
      let(:date_time_double) do
        instance_double(
          Cease::Eviction::Command::DateTime,
          tz: tz_double,
          parsed_in_timezone: instance.date_time.parsed_in_timezone,
          valid?: valid
        )
      end
      let(:tz_double) do
        instance_double(
          TZInfo::DataTimezone,
          to_local: date_time_local
        )
      end
      let(:date_time_local) { DateTime.parse('2022-01-01') }

      before do
        allow(instance).to receive(:date_time).and_return(date_time_double)
      end

      context "with an invalid date time" do
        let(:valid) { false }
        it { is_expected.to eq(false) }
      end

      context "with a valid date time" do
        let(:valid) { true }

        context "when the eviction is not overdue" do
          let(:date_time_local) { DateTime.parse('1999-01-01') }
          it { is_expected.to eq(false) }
        end

        context "when the eviction is overdue" do
          it { is_expected.to eq(true) }
        end
      end
    end
  end

  describe "#<=>" do
    subject { described_class.new(comment: comment) <=> other }

    let(:ast) { parsed_ruby[0] }
    let(:comment) { open_comment }

    context "when the comment is located before the ast" do
      let(:other) { ast.children.first }
      it { is_expected.to eq(-1) }
    end

    context "when the comment is located after the ast" do
      let(:other) { ast.children.last }
      it { is_expected.to eq(1) }
    end

    context "when the comment is the ast" do
      let(:other) { comment }
      it { is_expected.to eq(0) }
    end
  end

  describe "#nested_in?" do
    subject { described_class.new(comment: comment).nested_in?(other) }

    let(:ast) { parsed_ruby[0] }
    let(:comment) { open_comment }

    context "when the AST's end position is greater than" \
      "the comment's starting postition" do
      let(:other) { ast.children.last }
      it { is_expected.to eq(true) }
    end

    context "when the AST's end position is less than" \
      "the comment's starting postition" do
      let(:other) { ast.children.first }
      it { is_expected.to eq(false) }
    end
  end

  describe "#valid?" do
    subject { described_class.new(comment: comment).valid? }

    context "without a comment" do
      let(:comment) { nil }
      it { is_expected.to eq(false) }
    end

    context "with a close comment" do
      let(:comment) { close_comment }
      it { is_expected.to eq(true) }
    end

    context "with a open comment" do
      context "without parsed comments" do
        let(:comment) do
          instance_double(
            Parser::Source::Comment,
            text: "# this is a comment."
          )
        end

        it { is_expected.to eq(false) }
      end

      context "with parsed comments" do
        let(:comment) { open_comment }
        it { is_expected.to eq(true) }
      end
    end
  end
end
