require 'spec_helper'

describe Policial::StyleChecker do
  describe '#violations' do
    it 'returns a collection of computed violations' do
      stylish_file = stub_commit_file('good.rb', 'def good; end')
      violated_file = stub_commit_file('bad.rb', 'def bad( a ); a; end  ')
      bad_scss = stub_commit_file('bad.scss', 'h1 { border: none; }')
      pull_request =
        stub_pull_request(files: [stylish_file, violated_file, bad_scss])
      expected_violations = [
        'Avoid single-line method definitions.',
        'Space inside parentheses detected.',
        'Space inside parentheses detected.',
        'Trailing whitespace detected.',
        '`border: 0` is preferred over `border: none`'
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

    it 'allows disabling certain style guides via options' do
      ruby_file = stub_commit_file('bad.rb', 'def bad( a ); a; end  ')
      scss_file = stub_commit_file('bad.scss', 'h1 { border: none; }')
      pull_request = stub_pull_request(files: [ruby_file, scss_file])
      expected_violations = ['`border: 0` is preferred over `border: none`']

      violation_messages =
        described_class.new(pull_request, ruby: false).violations.map(&:message)

      expect(violation_messages).to eq expected_violations
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
