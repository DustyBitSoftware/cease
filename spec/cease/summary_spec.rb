require './lib/cease/summary'
require './lib/cease/examiner'

RSpec.describe Cease::Summary do
  class_attribute :clazz

  def hello(good_morning)
    p "beautiful"
  end

  class Error < StandardError; end

  let(:examiner_double) do
    instance_double(
      Cease::Examiner,
      overdue_evictions: overdue_evictions,
      source: source_double
    )
  end

  let(:overdue_eviction) do
    instance_double(
      Cease::Eviction::Context,
      description: description
    )
  end
  let(:description) do
    "[1:100] Overdue by roughly 10 days and 5 hours\n" \
    "class OverdueClass\n" \
    "end\n" \
  end
  let(:source_double) { instance_double(Pathname, to_s: "overdue_class.rb") }

  describe "#summarize" do
    subject { described_class.new(examiner: examiner_double).summarize }

    context "with overdue evictions" do
      let(:overdue_evictions) { [overdue_eviction] }  

      it "outputs the summary" do
        expect { subject }.to output(
          "(overdue_class.rb)\n\n" \
          "[1:100] Overdue by roughly 10 days and 5 hours\n" \
          "class OverdueClass\nend\n"
        ).to_stdout
      end
    end

    context "without overdue evictions" do
      let(:overdue_evictions) { [] }

      it "doesnt output anything" do
        expect { subject }.to_not output.to_stdout
      end
    end
  end
end
