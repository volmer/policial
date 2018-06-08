# frozen_string_literal: true

require 'spec_helper'

describe Policial::Linters::RuboCop::Investigator do
  let(:file) do
    double(
      'file',
      filename: 'app/test.rb',
      content: "# Test code\n\ndef hello()\n  puts 'Hey!'\nend"
    )
  end
  let(:config) { ::RuboCop::ConfigLoader.default_configuration }
  subject { described_class.new(file, config) }

  describe '#investigate' do
    it 'returns violations for each offense found by RuboCop' do
      violations = subject.investigate

      expect(violations.count).to eq 3

      expect(violations[0].filename).to eq('app/test.rb')
      expect(violations[0].line_range).to eq(5..5)
      expect(violations[0].linter).to eq('Layout/TrailingBlankLines')
      expect(violations[0].message).to eq(
        'Layout/TrailingBlankLines: Final newline missing.'
      )

      expect(violations[1].filename).to eq('app/test.rb')
      expect(violations[1].line_range).to eq(3..3)
      expect(violations[1].linter).to eq('Style/DefWithParentheses')
      expect(violations[1].message).to eq(
        'Style/DefWithParentheses: Omit the parentheses in defs when the '\
        "method doesn't accept any arguments."
      )

      expect(violations[2].filename).to eq('app/test.rb')
      expect(violations[2].line_range).to eq(1..1)
      expect(violations[2].linter).to eq('Style/FrozenStringLiteralComment')
      expect(violations[2].message).to eq(
        'Style/FrozenStringLiteralComment: Missing magic comment '\
        '`# frozen_string_literal: true`.'
      )
    end
  end
end
