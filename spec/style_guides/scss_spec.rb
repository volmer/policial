# frozen_string_literal: true

require 'spec_helper'

describe Policial::StyleGuides::Scss do
  subject do
    described_class.new(
      Policial::ConfigLoader.new(
        Policial::Commit.new('volmer/cerberus', 'commitsha', Octokit)
      )
    )
  end

  let(:custom_config) { nil }

  before do
    stub_contents_request_with_content(
      'volmer/cerberus',
      sha: 'commitsha',
      file: '.scss-lint.yml',
      content: custom_config.to_yaml
    )
  end

  describe '#violations_in_file' do
    it 'detects SCSS style guide violations' do
      file = build_file('test.scss', 'p { border: none; }')
      violations = subject.violations_in_file(file)

      expect(violations.count).to eq(1)
      expect(violations.first.filename).to eq('test.scss')
      expect(violations.first.line_number).to eq(1)
      expect(violations.first.linter).to eq('BorderZero')
      expect(violations.first.message).to eq(
        '`border: 0` is preferred over `border: none`'
      )
    end

    it 'reports syntax errors' do
      file = build_file('test.scss', 'p { border:')
      violations = subject.violations_in_file(file)

      expect(violations.count).to eq(1)
      expect(violations.first.filename).to eq('test.scss')
      expect(violations.first.line_number).to eq(2)
      expect(violations.first.linter).to eq('undefined')
      expect(violations.first.message).to eq(
        'Syntax Error: Invalid CSS after "p { border:": '\
        'expected expression (e.g. 1px, bold), was ""'
      )
    end

    it 'returns one violation per lint' do
      file_content = [
        'h1 { border: none; }',
        'h2 { border: none; content: "hi!"; }',
        'h3 { border: 0; }'
      ]
      file = build_file('test.scss', file_content)

      violations = subject.violations_in_file(file)

      expect(violations.count).to eq(3)

      expect(violations[0].filename).to eq('test.scss')
      expect(violations[0].line_number).to eq(1)
      expect(violations[0].linter).to eq('BorderZero')
      expect(violations[0].message).to eq(
        '`border: 0` is preferred over `border: none`'
      )

      expect(violations[1].filename).to eq('test.scss')
      expect(violations[1].line_number).to eq(2)
      expect(violations[1].linter).to eq('BorderZero')
      expect(violations[1].message).to eq(
        '`border: 0` is preferred over `border: none`'
      )

      expect(violations[2].filename).to eq('test.scss')
      expect(violations[2].line_number).to eq(2)
      expect(violations[2].linter).to eq('StringQuotes')
      expect(violations[2].message).to eq('Prefer single quoted strings')
    end

    it 'is idempotent' do
      file = build_file('test.scss', 'p { border: none; }')
      first_run = subject.violations_in_file(file)
      second_run = subject.violations_in_file(file)

      expect(first_run.count).to eq second_run.count
      expect(first_run.first.filename).to eq second_run.first.filename
      expect(first_run.first.line_number).to eq second_run.first.line_number
      expect(first_run.first.linter).to eq second_run.first.linter
      expect(first_run.first.message).to eq second_run.first.message
    end

    context 'with custom configuration' do
      let(:custom_config) do
        {
          'linters' => {
            'StringQuotes' => { 'style' => 'double_quotes' }
          }
        }
      end

      it 'detects offenses to the custom style guide' do
        file = build_file('test.scss', "p { content: 'hi!'; }")
        violations = subject.violations_in_file(file)

        expect(violations.count).to eq(1)
        expect(violations.first.filename).to eq('test.scss')
        expect(violations.first.line_number).to eq(1)
        expect(violations.first.linter).to eq('StringQuotes')
        expect(violations.first.message).to eq('Prefer double-quoted strings')
      end

      context 'with excluded files' do
        let(:custom_config) do
          {
            'linters' => {
              'StringQuotes' => {
                'exclude' => ['vendor/**', 'lib/style.scss']
              }
            }
          }
        end

        it 'has no violations' do
          file = build_file('vendor/test.scss', 'p { content: "hi!"; }')
          expect(subject.violations_in_file(file)).to be_empty

          file = build_file('lib/style.scss', 'p { content: "hi!"; }')
          expect(subject.violations_in_file(file)).to be_empty
        end
      end
    end
  end

  describe '#include_file?' do
    it 'matches SCSS files' do
      expect(subject.include_file?('my_file.scss')).to be true
      expect(subject.include_file?('app/base.scss')).to be true
      expect(subject.include_file?('my_file.css')).to be false
      expect(subject.include_file?('my_file.scss.erb')).to be false
    end

    context 'when custom config excludes the file' do
      let(:custom_config) do
        { 'exclude' => ['app/file.scss'] }
      end

      it 'is false' do
        expect(subject.include_file?('app/file.scss')).to be false
      end
    end
  end

  describe '#default_config_file' do
    it 'is .scss-lint.yml' do
      expect(subject.default_config_file).to eq('.scss-lint.yml')
    end
  end

  def build_file(name, *lines)
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
