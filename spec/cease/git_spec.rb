require 'git'

require './lib/cease/git'

RSpec.describe Cease::Git do
  let(:pwd) { Pathname.pwd.to_s }
  let(:git_base_double) { instance_double(Git::Base) }

  describe '.log' do
    subject { described_class.log }

    it 'returns the log from Git' do
      expect(Git).to receive(:open).with(pwd).
        and_return(git_base_double)
      expect(git_base_double).to receive(:log)

      subject
    end
  end

  describe '#log' do
    context "with a pwd argument" do
      subject { instance.log }

      let(:instance) { described_class.new(pwd: pwd) }
      let(:pwd) { 'some/path/to/a/project' }

      it 'returns the Git log for that directory' do
        expect(Git).to receive(:open).with('some/path/to/a/project')
          .and_return(git_base_double)
        expect(git_base_double).to receive(:log)

        subject
      end
    end

    context "without a pwd argument" do
      subject { instance.log }

      let(:instance) { described_class.new }

      it 'returns the log from Git' do
        expect(Git).to receive(:open).with(pwd).
          and_return(git_base_double)
        expect(git_base_double).to receive(:log)

        subject
      end
    end
  end
end
