# frozen_string_literal: true

require 'spec_helper'

describe Policial::StyleGuides::JavaScript do
  subject do
    described_class.new(
      Policial::ConfigLoader.new(
        Policial::Commit.new('volmer/cerberus', 'commitsha', Octokit)))
  end

  let(:custom_config) { nil }

  before do
    stub_contents_request_with_content(
      'volmer/cerberus',
      sha: 'commitsha',
      file: '.eslintrc.json',
      content: custom_config.to_json
    )
  end

  describe '#violations_in_file' do
    it 'returns one violation per lint' do
      file_content = [
        'var foo = function (bar) {',
        '  return "foobar;"',
        '}'
      ]
      file = build_file('test.js', file_content)

      violations = subject.violations_in_file(file)

      expect(violations.count).to eq(1)
      expect(violations[0].filename).to eq('test.js')
      expect(violations[0].line_number).to eq(1)
      expect(violations[0].linter).to eq('strict')
      expect(violations[0].message).to eq(
        "Use the function form of 'use strict'."
      )
    end

    context 'with valid file' do
      it 'has no violations' do
        file_content = [
          'function foo (bar) {',
          "  'use strict';",
          "  console.log('bar')",
          '}'
        ]
        file = build_file('test.js', file_content)
        expect(subject.violations_in_file(file)).to be_empty
      end
    end

    context 'with custom configuration' do
      let(:custom_config) do
        {
          'rules': {
            'no-plusplus' => 2
          }
        }
      end

      it 'detects offenses to the custom style guide' do
        file_content = [
          'var foo = 1;',
          'foo++;'
        ]
        file = build_file('test.js', file_content)

        violations = subject.violations_in_file(file)

        expect(violations.count).to eq(1)
        expect(violations[0].message).to eq("Unary operator '++' used.")
      end
    end
  end

  describe '#filename_patterns' do
    it 'matches Javascript files' do
      expect(subject.filename_patterns.first).to match('my_file.js')
      expect(subject.filename_patterns.first).to match('app/script.js')
      expect(subject.filename_patterns.first).not_to match('my_file.js.erb')
      expect(subject.filename_patterns.first).not_to match('my_file.coffee')
    end
  end

  describe '#default_config_file' do
    it 'is .eslint.rc.json' do
      expect(subject.default_config_file).to eq('.eslintrc.json')
    end
  end

  describe '#exclude_file?' do
    it 'is false' do
      expect(subject.exclude_file?('filename')).to eq(false)
    end
  end

  def build_file(name, *lines)
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
