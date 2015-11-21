require 'spec_helper'

describe Policial::StyleChecker do
  describe '#violations' do
    it 'returns a collection of computed violations' do
      stylish_file = stub_commit_file('good.rb', 'def good; end')
      violated_file = stub_commit_file('bad.rb', 'def bad( a ); a; end  ')
      pull_request =
        stub_pull_request(files: [stylish_file, violated_file])
      expected_violations = [
        'Avoid single-line method definitions.',
        'Space inside parentheses detected.',
        'Space inside parentheses detected.',
        'Trailing whitespace detected.'
      ]

      violation_messages =
        described_class.new(pull_request).violations.map(&:message)

      expect(violation_messages).to eq expected_violations
    end

    it 'forwards options to RepoConfig' do
      file = stub_commit_file('ruby.rb', 'puts 123')
      pull_request = stub_pull_request(files: [file])

      expect(Policial::RepoConfig).to receive(:new).with(
        anything, my: :options).and_call_original

      described_class.new(pull_request, my: :options).violations
    end

    context 'for a Ruby file' do
      context 'with violations' do
        it 'returns violations' do
          file = stub_commit_file('ruby.rb', 'puts 123    ')
          pull_request = stub_pull_request(files: [file])

          violations = described_class.new(pull_request).violations
          messages = violations.map(&:message)

          expect(messages).to eq ['Trailing whitespace detected.']
        end
      end

      context 'with violation on unchanged line' do
        it 'returns no violations' do
          file = stub_commit_file(
            'foo.rb', '"wrong quotes"', Policial::UnchangedLine.new
          )
          pull_request = stub_pull_request(files: [file])

          violations = described_class.new(pull_request).violations

          expect(violations.count).to eq 0
        end
      end

      context 'without violations' do
        it 'returns no violations' do
          file = stub_commit_file('ruby.rb', 'puts 123')
          pull_request = stub_pull_request(files: [file])

          violations = described_class.new(pull_request).violations

          expect(violations).to be_empty
        end
      end
    end

    context 'with unsupported file type' do
      it 'uses unsupported style guide' do
        file = stub_commit_file('fortran.f', %({PRINT *, 'Hello World!'\nEND}))
        pull_request = stub_pull_request(files: [file])

        violations = described_class.new(pull_request).violations

        expect(violations).to eq []
      end
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
