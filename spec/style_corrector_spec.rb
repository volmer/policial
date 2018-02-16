# frozen_string_literal: true

require 'spec_helper'

describe Policial::StyleCorrector do
  let(:head_commit) { double('Commit', file_content: '') }
  let(:pull_request) do
    stub_pull_request(head_commit: head_commit, files: files)
  end
  let(:options) { {} }
  subject { described_class.new(pull_request, options).corrected_files }

  describe '#corrected_files' do
    context 'returns a an array of corrected files' do
      let(:files) do
        [
          stub_commit_file('good.rb',
                           "# frozen_string_literal: true\n\ndef good; end"),
          stub_commit_file('bad.rb', "def bad( a ); a; end  "),
          stub_commit_file('bad.coffee', 'foo: =>')
        ]
      end

      it do
        expect(subject.map(&:class)).to eq [Policial::CorrectedFile]
      end
      it { expect(subject[0].filename).to eq 'bad.rb' }
      it { expect(subject[0].content).to eq <<~FILE }
        # frozen_string_literal: true

        def bad(a)
          a
        end
      FILE
      it { expect(subject[0].uncorrected_content).to eq "def bad( a ); a; end  \n" }
    end

    context 'forwards options to the linters, as well as a config loader' do
      let(:files) do
        [stub_commit_file('ruby.rb', 'puts 123')]
      end
      let(:options) do
        {
          ruby: { my: :options },
          coffeescript: { a_few: :more_options }
        }
      end

      before do
        config_loader = Policial::ConfigLoader.new(head_commit)

        expect(Policial::ConfigLoader)
          .to receive(:new)
          .with(head_commit)
          .and_return(config_loader)

        expect(Policial::Linters::Ruby).to receive(:new)
          .with(config_loader, my: :options).and_call_original
        expect(Policial::Linters::CoffeeScript).to receive(:new)
          .with(config_loader, a_few: :more_options).and_call_original
      end

      it { expect(subject.size).to eq 1 }
    end

    context 'skips linters on files that they are not able to investigate' do
      let(:files) do
        [
          stub_commit_file('a.rb', '"double quotes"'),
          stub_commit_file('b.rb', ':trailing_withespace ')
        ]
      end

      before do
        allow_any_instance_of(Policial::Linters::Ruby)
          .to receive(:investigate?).with('a.rb').and_return(false)
        allow_any_instance_of(Policial::Linters::Ruby)
          .to receive(:investigate?).with('b.rb').and_return(true)
      end

      it { expect(subject.size).to eq 1 }
      it { expect(subject.first.filename).to eq 'b.rb' }
    end

    private

    def stub_pull_request(options = {})
      head_commit = double('Commit', file_content: '')
      defaults = {
        file_content: '',
        head_commit: head_commit,
        files: []
      }

      double('PullRequest', defaults.merge(options))
    end

    def stub_commit_file(filename, contents, line = nil)
      line ||= Policial::Line.new(1, 'foo', 2)
      formatted_contents = "#{contents}\n"
      double(
        filename.split('.').first,
        filename: filename,
        content: formatted_contents,
        removed?: false,
        line_at: line
      )
    end
  end
end
