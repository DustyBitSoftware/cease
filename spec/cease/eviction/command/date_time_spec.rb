require './lib/cease/eviction/command/date_time'
require './lib/cease/eviction/comment'

RSpec.describe Cease::Eviction::Command::DateTime do
  it "extends Forwardable" do
    expect(described_class.ancestors).to include(Forwardable)
  end

  let(:instance) { described_class.new(comment_double, date_time, options) }
  let(:comment_double) { instance_double(Cease::Eviction::Comment) }
  let(:date_time) { "at 6pm on 1/1/2021" }
  let(:options) { "" }

  describe "#parsed_in_timezone" do
    subject { instance.parsed_in_timezone }
    let(:tz) { TZInfo::Timezone.get(timezone) }
    let(:timezone) { 'UTC' }

    context "when valid" do
      context "with a date" do
        context "without a timezone" do
          it "returns the datetime in UTC" do
            expect(subject).to eq('Fri, 01 Jan 2021 18:00:00 +0000')
          end
        end

        context "with a timezone" do
          let(:options) { "{ timezone: 'PST' }" }

          it "returns the datetime in that timezone" do
            expect(subject).to eq('Fri, 01 Jan 2021 18:00:00 -0800')
          end
        end
      end

      context "without a date" do
        let(:date_time) { "at 6pm" }

        context "with a last commit date" do
          let(:comment_double) do
            instance_double(
              Cease::Eviction::Comment,
              last_commit_date: DateTime.parse("2000-12-01 12:00:00")
            )
          end

          it "returns the datetime of the last commit" do
            expect(subject).to eq("Fri, 01 Dec 2000 12:00:00 +0000")
          end
        end

        context "without a last commit date" do
          let(:comment_double) do
            instance_double(Cease::Eviction::Comment, last_commit_date: nil)
          end

          it "returns the current datetime" do
            expect(DateTime).to receive(:now)
              .and_return(DateTime.parse("2022-12-01 12:00:00"))
            expect(subject).to eq("Fri, 01 Dec 2022 12:00:00 +0000")
          end
        end
      end
    end

    context "when invalid" do
      let(:date_time) { "at eleven am" }

      before do
        allow(comment_double).to receive(:last_commit_date).and_return(nil)
      end

      it { is_expected.to eq(nil) }
    end
  end

  describe "#valid?" do
    subject { instance.valid? }

    context "with time" do
      context "with valid time" do
        context "with date" do
          context "valid date" do
            context "with timezone" do
              let(:options) { "{ timezone: 'PST' }" }

              context "with recognized timezone" do
                it { is_expected.to eq(true) }
              end

              context "with unrecognized timezone" do
                let(:options) { "{ timezone: 'OTC' }" }
                it { is_expected.to eq(false) }
              end

              context "with unparsable options" do
                let(:options) { ",.?" }
                it { is_expected.to eq(false) }
              end
            end

            context "without timezone" do
              it { is_expected.to eq(true) }
            end
          end

          context "invalid date" do
            let(:date_time) { "at 11am on 99/99/9999" }
            it { is_expected.to eq(false) }
          end
        end

        context "without date" do
          let(:date_time) { "at 9:00pm" }

          context "with timezone" do
            context "with recognized timezone" do
              it { is_expected.to eq(true) }
            end

            context "with unrecognized timezone" do
              let(:options) { "{ timezone: 'OTC' }" }
              it { is_expected.to eq(false) }
            end

            context "with unparsable options" do
              let(:options) { ",.?" }
              it { is_expected.to eq(false) }
            end
          end
        end
      end

      context "with invalid time" do
        let(:date_time) { "at eleven am" }
        it { is_expected.to eq(false) }
      end
    end

    context "without time" do
      let(:date_time) { "on 1/1/2000" }
      it { is_expected.to eq(false) }
    end

    context "with an exception" do
      before do
        allow(instance).to receive(:valid_time?).and_raise(StandardError)
      end

      it "doesn't raise the exception" do
        expect { subject }.to_not raise_error
      end

      it { is_expected.to eq(false) }
    end
  end

  describe "#guess?" do
    subject { instance.guess? }

    context "with a parsable date" do
      it { is_expected.to eq(true) }
    end

    context "with an unparsable date" do
      let(:date_time) { "at 6pm on nineninenine" }
      it { is_expected.to eq(true) }
    end

    context "without a date" do
      let(:date_time) { "at 6pm" }
      it { is_expected.to eq(true) }
    end
  end

  describe "#tz" do
    subject { instance.tz }

    context "without a timezone" do
      it "returns the tz instance for UTC" do
        expect(subject).to eq(TZInfo::Timezone.get('Etc/UTC'))
      end
    end

    context "with an recognized timezone" do
      let(:options) { "{ timezone: 'EST'}" }

      it "returns the TZ instance for that timezone" do
        expect(subject).to eq(TZInfo::Timezone.get('America/New_York'))
      end
    end

    context "with an unrecognized timezone" do
      let(:options) { "{ timezone: 'OOO'}" }

      it "returns the TZ instance for UTC" do
        expect(subject).to eq(TZInfo::Timezone.get('Etc/UTC'))
      end
    end

    context "with unparsable timezone" do
      let(:options) { ",.?" }

      it "raises an exception" do
        expect { subject }.to raise_error(
          Cease::Eviction::Command::DateTime::BadOptionsError
        )
      end
    end
  end
end
