require 'spec_helper'

describe Policial::StyleGuides::Ruby do
  subject do
    described_class.new(
      Policial::RepoConfig.new(
        Policial::Commit.new('volmer/cerberus', 'commitsha', Octokit)
      )
    )
  end
  let(:custom_config) { nil }

  describe '#enabled?' do
    it 'is true' do
      expect(subject.enabled?).to be true
    end
  end

  describe '#violations_in_file' do
    before do
      stub_contents_request_with_content(
        'volmer/cerberus',
        sha: 'commitsha',
        file: '.rubocop.yml',
        content: custom_config.to_yaml
      )
    end

    it 'detects offenses to the Ruby community Style Guide' do
      file = build_file('test.rb', "\"I am naughty\"\n")
      violations = subject.violations_in_file(file)

      expect(violations.count).to eq(1)
      expect(violations.first.filename).to eq('test.rb')
      expect(violations.first.line_number).to eq(1)
      expect(violations.first.messages).to eq([
        "Prefer single-quoted strings when you don't need string interpolation"\
        ' or special symbols.'
      ])
    end

    it 'returns only one violation containing all offenses per line' do
      file_content =
        ['{first_line: :violates }', '"second too!".to_sym', "'third ok'\n"]
      file = build_file('test.rb', file_content)

      violations = subject.violations_in_file(file)

      expect(violations.count).to eq(2)

      expect(violations.first.filename).to eq('test.rb')
      expect(violations.first.line_number).to eq(1)
      expect(violations.first.messages).to eq([
        'Literal `{first_line: :violates }` used in void context.',
        'Space inside { missing.'
      ])

      expect(violations.last.filename).to eq('test.rb')
      expect(violations.last.line_number).to eq(2)
      expect(violations.last.messages).to eq([
        "Prefer single-quoted strings when you don't need string interpolation"\
        ' or special symbols.'
      ])
    end

    context 'with custom configuration' do
      let(:custom_config) do
        {
          'StringLiterals' => {
            'EnforcedStyle' => 'double_quotes',
            'Enabled' => 'true'
          }
        }
      end

      it 'detects offenses to the custom style guide' do
        file = build_file('test.rb', "'You do not like me'\n")
        violations = subject.violations_in_file(file)

        expect(violations.count).to eq(1)
        expect(violations.first.filename).to eq('test.rb')
        expect(violations.first.line_number).to eq(1)
        expect(violations.first.messages).to eq([
          'Prefer double-quoted strings unless you need single quotes to '\
          'avoid extra backslashes for escaping.'
        ])
      end
    end

    context 'with ShowCopNames' do
      let(:custom_config) do
        { 'ShowCopNames' => 'true' }
      end

      it 'includes RuboCop cop names in violation messages' do
        file = build_file('test.rb', '"I am naughty"')
        violation = subject.violations_in_file(file).first

        expect(violation.messages).to include(
          "Style/StringLiterals: Prefer single-quoted strings when you don't "\
          'need string interpolation or special symbols.'
        )
      end
    end

    context 'with excluded files' do
      let(:custom_config) do
        {
          'AllCops' => {
            'Exclude' => ['lib/test.rb']
          }
        }
      end

      it 'has no violations' do
        file = build_file('lib/test.rb', 4, '"Awful code"')
        violations = subject.violations_in_file(file)

        expect(violations).to be_empty
      end
    end
  end

  describe '.config_file' do
    it 'is the default RuboCop dotfile' do
      expect(described_class.config_file).to eq('.rubocop.yml')
    end

    it 'can be overwritten' do
      old_value = described_class.config_file

      described_class.config_file = '.policial.yml'
      expect(described_class.config_file).to eq('.policial.yml')

      described_class.config_file = old_value
    end
  end

  def build_file(name, *lines)
    file = double('CommitFile', filename: name, content: lines.join("\n"))
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
