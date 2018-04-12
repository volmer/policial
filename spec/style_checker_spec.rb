# frozen_string_literal: true

require 'spec_helper'

describe Policial::StyleChecker do
  let(:ruby_linter) { Policial::Linters::Ruby.new }
  let(:coffeescript_linter) { Policial::Linters::CoffeeScript.new }
  let(:linters) { [ruby_linter, coffeescript_linter] }

  describe '#violations' do
    it 'returns a collection of computed violations' do
      stylish_file = stub_commit_file('good.rb', 'def good; end')
      violated_file = stub_commit_file('bad.rb', 'def bad( args ); args; end  ')
      bad_coffee = stub_commit_file('bad.coffee', 'foo: =>')
      pull_request =
        stub_pull_request(files: [stylish_file, violated_file, bad_coffee])
      expected_violations = [
        'Style/FrozenStringLiteralComment: Missing magic comment `# '\
        'frozen_string_literal: true`.',
        'Layout/SpaceInsideParens: Space inside parentheses detected.',
        'Layout/SpaceInsideParens: Space inside parentheses detected.',
        'Layout/TrailingWhitespace: Trailing whitespace detected.',
        'Style/FrozenStringLiteralComment: Missing magic comment `# '\
        'frozen_string_literal: true`.',
        'Style/SingleLineMethods: Avoid single-line method definitions.',
        'Unnecessary fat arrow'
      ]

      violation_messages = described_class.new(
        pull_request, linters: linters
      ).violations.map(&:message)

      expect(violation_messages).to eq expected_violations
    end

    it 'forwards a commit to linters' do
      file = stub_commit_file('ruby.rb', 'puts 123')
      commit = double('Commit', file_content: '')
      pull_request = stub_pull_request(head_commit: commit, files: [file])

      expect(ruby_linter).to receive(:violations)
        .with(file, commit).and_call_original
      expect(coffeescript_linter).to receive(:violations)
        .with(file, commit).and_call_original

      described_class.new(pull_request, linters: linters).violations
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
