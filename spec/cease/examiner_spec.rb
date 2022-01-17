require './lib/cease/examiner'

RSpec.describe Cease::Examiner do
  let(:source_double) { instance_double(Pathname) }
  let(:overdue_eviction) do
    instance_double(Cease::Eviction::Context, overdue?: true)
  end
  let(:pending_eviction) do
    instance_double(Cease::Eviction::Context, overdue?: false)
  end

  describe "#evictions" do
    subject { described_class.new(source: source_double).evictions }

    let(:evictions) { [overdue_eviction, pending_eviction] }

    it "returns the evictions" do
      expect(Cease::Eviction::Context).to receive(:from_source)
        .with(source: source_double)
        .and_return(evictions)

      expect(subject).to eq(evictions)
    end
  end

  describe "#summarize" do
    subject { examiner_instance.summarize }

    let(:examiner_instance) { described_class.new(source: source_double) }
    let(:summary_double) { instance_double(Cease::Summary) }

    context "with overdue evictions" do
      before do
        allow(Cease::Eviction::Context).to receive(:from_source)
          .with(source: source_double)
          .and_return([overdue_eviction])
      end

      it "sumarizes the overdue evictions" do
        expect(Cease::Summary).to receive(:new)
          .with(examiner: examiner_instance)
          .and_return(summary_double)
        expect(summary_double).to receive(:summarize)
        
        subject
      end
    end

    context "with no overdue evictions" do
      before do
        allow(Cease::Eviction::Context).to receive(:from_source)
          .with(source: source_double)
          .and_return([pending_eviction])
      end

      it { is_expected.to eq(nil) }
    end
  end

  describe "#summarizable" do
    subject { described_class.new(source: source_double ).summarizable? }

    context "with overdue evictions" do
      before do
        allow(Cease::Eviction::Context).to receive(:from_source)
          .with(source: source_double)
          .and_return([overdue_eviction])
      end

      it { is_expected.to eq(true) }
    end

    context "without overdue evictions" do
      before do
        allow(Cease::Eviction::Context).to receive(:from_source)
          .with(source: source_double)
          .and_return([pending_eviction])
      end

      it { is_expected.to eq(false) }
    end
  end

  describe "#overdue_evictions" do
    subject { described_class.new(source: source_double ).overdue_evictions }

    before do
      allow(Cease::Eviction::Context).to receive(:from_source)
        .with(source: source_double)
        .and_return([overdue_eviction, pending_eviction])
    end

    it { is_expected.to contain_exactly(overdue_eviction) }
  end
end
