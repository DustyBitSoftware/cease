require './lib/cease/cli'

RSpec.describe Cease::CLI do
  describe "#execute" do
    subject { described_class.new(argv: argv).execute }

    let(:argv) { [] }
    let(:report_double) { instance_double(Cease::Report) }

    context "without argv" do
      # Pretend the current working directory has a single file.
      let(:pathname_double) do
        instance_double(Pathname, entries: [nested_pathname] )
      end
      let(:nested_pathname) do
        instance_double(
          Pathname,
          exist?: true,
          basename: 'important_class.rb',
          extname: '.rb'
        )
      end

      before do
        allow(Pathname).to receive(:new).with('.').and_return(pathname_double)
        # A file will yield itself when calling `.find`.
        allow(nested_pathname).to receive(:find).and_yield(nested_pathname)
      end

      it "executes a report on the working directory" do
        expect(Cease::Report).to receive(:new)
          .with(sources: [nested_pathname])
          .and_return(report_double)
        expect(report_double).to receive(:execute)

        subject
      end
    end

    context "with argv" do
      context "with a file that exists" do
        let(:filename) { 'some_ruby_class.rb' }
        let(:argv) { [filename] }
        let(:pathname_double) do
          instance_double(
            Pathname,
            exist?: true,
            basename: filename,
            extname: '.rb'
          )
        end
        let(:sources) { [pathname_double] } 

        before do
          # Pretend the file exists in the working directory.
          allow(Pathname).to receive(:new).with(filename)
            .and_return(pathname_double)
          allow(pathname_double).to receive(:find)
            .and_yield(pathname_double)
        end

        it 'executes the report on the sources' do
          expect(Cease::Report).to receive(:new).with(sources: sources)
            .and_return(report_double)
          expect(report_double).to receive(:execute)

          subject
        end
      end

      context "with a file that does not exist" do
        let(:filename) { 'does_not_exist.rb' }
        let(:argv) { [filename] }

        it 'executes the report with empty sources' do
          expect(Cease::Report).to receive(:new).with(sources: [])
            .and_return(report_double)
          expect(report_double).to receive(:execute)

          subject
        end
      end

      context "with a existing directory" do
        let(:directory_name) { 'directory' }
        let(:argv) { [directory_name] }
        let(:filename_in_directory) { 'some_file.rb' } 
        let(:pathname_double) do
          instance_double(Pathname, exist?: true, basename: directory_name)
        end
        let(:nested_pathname) do
          instance_double(
            Pathname,
            exist?: true,
            basename: filename_in_directory,
            extname: '.rb'
          )
        end

        before do
          allow(Pathname).to receive(:new).with(directory_name)
            .and_return(pathname_double)
          allow(pathname_double).to receive(:find).and_yield(nested_pathname)
        end

        it 'executes the report on Ruby files' do
          expect(Cease::Report).to receive(:new)
            .with(sources: [nested_pathname])
            .and_return(report_double)
          expect(report_double).to receive(:execute)

          subject
        end
      end

      context "with a hidden entry" do
        let(:hidden_file) { '.hidden.rb' }
        let(:argv) { [hidden_file] }
        let(:pathname_double) do
          instance_double(Pathname, exist?: true, basename: hidden_file)
        end

        before do
          allow(Pathname).to receive(:new).with(hidden_file)
            .and_return(pathname_double)
        end

        it 'executes the report with empty sources' do
          expect(Cease::Report).to receive(:new).with(sources: [])
            .and_return(report_double)
          expect(report_double).to receive(:execute)

          subject
        end
      end

      context "with a non-Ruby file" do
        let(:non_ruby_file) { 'main.rs' }
        let(:argv) { [non_ruby_file] }
        let(:pathname_double) do
          instance_double(
            Pathname, exist?: true,
            basename: non_ruby_file,
            extname: Pathname.new(non_ruby_file).extname
          )
        end

        before do
          allow(Pathname).to receive(:new).with(non_ruby_file)
            .and_return(pathname_double)
          allow(pathname_double).to receive(:find).and_yield(pathname_double)
        end

        it 'executes the report with empty sources' do
          expect(Cease::Report).to receive(:new).with(sources: [])
            .and_return(report_double)
          expect(report_double).to receive(:execute)

          subject
        end
      end
    end
  end
end
