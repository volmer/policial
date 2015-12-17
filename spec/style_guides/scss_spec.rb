require 'spec_helper'

describe Policial::StyleGuides::Scss do
  subject do
    described_class.new(
      Policial::RepoConfig.new(
        Policial::Commit.new('volmer/cerberus', 'commitsha', Octokit)
      )
    )
  end
  let(:custom_config) { nil }

  describe '#violations_in_file' do
    before do
      stub_contents_request_with_content(
        'volmer/cerberus',
        sha: 'commitsha',
        file: '.scss-lint.yml',
        content: custom_config.to_yaml
      )
    end

    it 'detects offenses to the Ruby community Style Guide' do
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
            'exclude' => ['assets/**'],
            'linters' => {
              'StringQuotes' => {
                'exclude' => ['vendor/**', 'lib/style.scss']
              }
            }
          }
        end

        it 'has no violations' do
          file = build_file('assets/ugly.scss', 'p { content: "hi!"; }')
          expect(subject.violations_in_file(file)).to be_empty

          file = build_file('vendor/test.scss', 'p { content: "hi!"; }')
          expect(subject.violations_in_file(file)).to be_empty

          file = build_file('lib/style.scss', 'p { content: "hi!"; }')
          expect(subject.violations_in_file(file)).to be_empty
        end
      end
    end

    it 'ignores non .scss files' do
      file = build_file('ugly.css', 'p { content: "hi!"; }')
      expect(subject.violations_in_file(file)).to be_empty
    end
  end

  describe '#config_file' do
    it 'is the default SCSS Lint dotfile' do
      expect(subject.config_file).to eq('.scss-lint.yml')
    end
  end

  def build_file(name, *lines)
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
