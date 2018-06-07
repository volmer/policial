# frozen_string_literal: true

require 'spec_helper'

describe Policial::Linters::SCSSLint do
  subject { described_class.new }

  let(:custom_config) { nil }

  let(:commit) { Policial::Commit.new('volmer/cerberus', 'commitsha', Octokit) }

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
      violations = subject.violations(file, commit)

      expect(violations.count).to eq(1)
      expect(violations.first.filename).to eq('test.scss')
      expect(violations.first.line_range).to eq(1..1)
      expect(violations.first.linter).to eq('BorderZero')
      expect(violations.first.message).to eq(
        '`border: 0` is preferred over `border: none`'
      )
    end

    it 'reports syntax errors' do
      file = build_file('test.scss', 'p { border:')
      violations = subject.violations(file, commit)

      expect(violations.count).to eq(1)
      expect(violations.first.filename).to eq('test.scss')
      expect(violations.first.line_range).to eq(2..2)
      expect(violations.first.linter).to eq('Syntax')
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

      violations = subject.violations(file, commit)

      expect(violations.count).to eq(3)

      expect(violations[0].filename).to eq('test.scss')
      expect(violations[0].line_range).to eq(1..1)
      expect(violations[0].linter).to eq('BorderZero')
      expect(violations[0].message).to eq(
        '`border: 0` is preferred over `border: none`'
      )

      expect(violations[1].filename).to eq('test.scss')
      expect(violations[1].line_range).to eq(2..2)
      expect(violations[1].linter).to eq('BorderZero')
      expect(violations[1].message).to eq(
        '`border: 0` is preferred over `border: none`'
      )

      expect(violations[2].filename).to eq('test.scss')
      expect(violations[2].line_range).to eq(2..2)
      expect(violations[2].linter).to eq('StringQuotes')
      expect(violations[2].message).to eq('Prefer single quoted strings')
    end

    it 'is idempotent' do
      file = build_file('test.scss', 'p { border: none; }')
      first_run = subject.violations(file, commit)
      second_run = subject.violations(file, commit)

      expect(first_run.count).to eq second_run.count
      expect(first_run.first.filename).to eq second_run.first.filename
      expect(first_run.first.line_range).to eq second_run.first.line_range
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

      it 'detects offenses to the custom linter' do
        file = build_file('test.scss', "p { content: 'hi!'; }")
        violations = subject.violations(file, commit)

        expect(violations.count).to eq(1)
        expect(violations.first.filename).to eq('test.scss')
        expect(violations.first.line_range).to eq(1..1)
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
          expect(subject.violations(file, commit)).to be_empty

          file = build_file('lib/style.scss', 'p { content: "hi!"; }')
          expect(subject.violations(file, commit)).to be_empty
        end
      end
    end

    context 'when custom config requires a gem that cannot be loaded' do
      let(:custom_config) do
        { 'plugin_gems' => ['missing_plugin'] }
      end

      it 'raises Policial::ConfigDependencyError' do
        file = build_file('test.scss', "p { content: 'hi!'; }")
        expect { subject.violations(file, commit) }
          .to raise_error(
            Policial::ConfigDependencyError,
            "Unable to load linter plugin gem 'missing_plugin'. Try running "\
            '`gem install missing_plugin`, or adding it to your Gemfile and '\
            'running `bundle install`. See the `plugin_gems` section of your '\
            '.scss-lint.yml file to add/remove gem plugins.'
          )
      end
    end

    context 'when a linter error happens' do
      before do
        allow_any_instance_of(SCSSLint::Runner)
          .to receive(:run).and_raise(SCSSLint::Exceptions::LinterError, 'No!')
      end

      it 'raises Policial::ConfigDependencyError' do
        file = build_file('test.scss', "p { content: 'hi!'; }")
        expect { subject.violations(file, commit) }
          .to raise_error(Policial::LinterError, 'No!')
      end
    end

    it 'ignores non SCSS files' do
      file = build_file('my_file.css', 'p { border: none; }')
      expect(subject.violations(file, commit)).to be_empty
    end

    context 'when custom config excludes a file' do
      let(:custom_config) do
        { 'exclude' => ['app/file.scss'] }
      end

      it 'ignores the file' do
        file = build_file('app/file.scss', 'p { border: none; }')
        expect(subject.violations(file, commit)).to be_empty
      end
    end

    context 'with custom config file name' do
      subject { described_class.new(config_file: 'custom_scss.yml') }

      before do
        stub_contents_request_with_content(
          'volmer/cerberus',
          sha: 'commitsha',
          file: 'custom_scss.yml',
          content:  {
            'linters' => {
              'StringQuotes' => { 'style' => 'double_quotes' }
            }
          }.to_yaml
        )
      end

      it 'detects offenses to the custom config' do
        file = build_file('test.scss', "p { content: 'hi!'; }")
        violations = subject.violations(file, commit)

        expect(violations.count).to eq(1)
        expect(violations.first.filename).to eq('test.scss')
        expect(violations.first.line_range).to eq(1..1)
        expect(violations.first.linter).to eq('StringQuotes')
        expect(violations.first.message).to eq('Prefer double-quoted strings')
      end
    end
  end

  describe '#correct' do
    it 'is nil' do
      file = build_file('test.scss', 'foo')
      expect(subject.correct(file, commit)).to be nil
    end
  end

  def build_file(name, *lines)
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
