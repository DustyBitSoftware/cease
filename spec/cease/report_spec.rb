require './lib/cease/report'
require_relative '../spec_helper'

RSpec.describe Cease::Report do
  let(:source_with_evictions) { instance_double(Pathname) }
  let(:source_without_evictions) { instance_double(Pathname) }

  let(:examiner_with_evictions) do
    instance_double(
      Cease::Examiner,
      overdue_evictions: [overdue_eviction],
      summarizable?: true
    )
  end
  let(:examiner_without_evictions) do
    instance_double(
      Cease::Examiner,
      overdue_evictions: [],
      summarizable?: false
    )
  end
  let(:overdue_eviction) { instance_double(Cease::Eviction::Context) }

  before do
    allow(Cease::Examiner).to receive(:new)
      .with(source: source_with_evictions)
      .and_return(examiner_with_evictions)

    allow(Cease::Examiner).to receive(:new)
      .with(source: source_without_evictions)
      .and_return(examiner_without_evictions)
  end

  describe '#execute' do
    subject { described_class.new(sources: sources).execute }

    let(:sources) { [source_with_evictions, source_without_evictions ]}

    context "with overdue evictions" do
      it 'summarizes the examiner and returns the exit code' do
        aggregate_failures do
          expect(examiner_with_evictions).to receive(:summarize)
          expect { subject }.to output(
            "\nScanning 2 source(s)...\n\n" \
            "\nTotal of 1 evictions(s) found.\n"
          ).to_stdout
          expect(subject).to eq(1)
        end
      end
    end

    context "with no overdue evictions" do
      let(:sources) { [source_without_evictions] }

      it 'outputs the header and returns the exit code' do
        aggregate_failures do
          expect(examiner_without_evictions).to_not receive(:summarize)
          expect { subject }.to output(
            "\nScanning 1 source(s)...\n\n" \
          ).to_stdout
          expect(subject).to eq(0)
        end
      end
    end
  end
end
