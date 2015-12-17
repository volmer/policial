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
      file = build_file('test.rb', '"I am naughty"')
      violations = subject.violations_in_file(file)

      expect(violations.count).to eq(1)
      expect(violations.first.filename).to eq('test.rb')
      expect(violations.first.line_number).to eq(1)
      expect(violations.first.linter).to eq('Style/StringLiterals')
      expect(violations.first.message).to eq(
        "Prefer single-quoted strings when you don't need string interpolation"\
        ' or special symbols.'
      )
    end

    it 'returns one violation per offense' do
      file_content =
        ['{first_line: :violates }', '"second too!".to_sym', "'third ok'"]
      file = build_file('test.rb', file_content)

      violations = subject.violations_in_file(file)

      expect(violations.count).to eq(3)

      expect(violations[0].filename).to eq('test.rb')
      expect(violations[0].line_number).to eq(1)
      expect(violations[0].linter).to eq('Lint/Void')
      expect(violations[0].message).to eq(
        'Literal `{first_line: :violates }` used in void context.'
      )

      expect(violations[1].filename).to eq('test.rb')
      expect(violations[1].line_number).to eq(1)
      expect(violations[1].linter).to eq('Style/SpaceInsideHashLiteralBraces')
      expect(violations[1].message).to eq('Space inside { missing.')

      expect(violations[2].filename).to eq('test.rb')
      expect(violations[2].line_number).to eq(2)
      expect(violations[2].linter).to eq('Style/StringLiterals')
      expect(violations[2].message).to eq(
        "Prefer single-quoted strings when you don't need string interpolation"\
        ' or special symbols.'
      )
    end

    context 'with custom configuration' do
      let(:custom_config) do
        {
          'Style/StringLiterals' => {
            'EnforcedStyle' => 'double_quotes'
          }
        }
      end

      it 'detects offenses to the custom style guide' do
        file = build_file('test.rb', "'You do not like me'")
        violations = subject.violations_in_file(file)

        expect(violations.count).to eq(1)
        expect(violations.first.filename).to eq('test.rb')
        expect(violations.first.line_number).to eq(1)
        expect(violations.first.linter).to eq('Style/StringLiterals')
        expect(violations.first.message).to eq(
          'Prefer double-quoted strings unless you need single quotes to '\
          'avoid extra backslashes for escaping.'
        )
      end

      context 'with excluded files' do
        let(:custom_config) do
          {
            'AllCops' => {
              'Exclude' => ['app/models/ugly.rb']
            },
            'Style/StringLiterals' => {
              'Exclude' => ['lib/**/*', 'config/ext.rb']
            }
          }
        end

        it 'has no violations' do
          file = build_file('app/models/ugly.rb', '"Awful code"')
          expect(subject.violations_in_file(file)).to be_empty

          file = build_file('lib/test.rb', '"Awful code"')
          expect(subject.violations_in_file(file)).to be_empty

          file = build_file('config/ext.rb', '"Awful code"')
          expect(subject.violations_in_file(file)).to be_empty
        end
      end
    end

    it 'ignores Rails cops by default' do
      file = build_file('app/models/ugly.rb', "puts 'my logs'")
      expect(subject.violations_in_file(file)).to be_empty
    end

    context 'when custom config enables Rails cops' do
      let(:custom_config) do
        { 'AllCops' => { 'RunRailsCops' => true } }
      end

      it 'runs Rails cops' do
        file = build_file('app/models/ugly.rb', "puts 'my logs'")
        expect(subject.violations_in_file(file)).not_to be_empty
      end
    end

    context 'when custom config explicitly disables Rails cops' do
      let(:custom_config) do
        { 'AllCops' => { 'RunRailsCops' => false } }
      end

      it 'ignores Rails cops' do
        file = build_file('app/models/ugly.rb', "puts 'my logs'")
        expect(subject.violations_in_file(file)).to be_empty
      end
    end

    it 'ignores non .rb files' do
      file = build_file('ugly.erb', '"double quotes"')
      expect(subject.violations_in_file(file)).to be_empty
    end
  end

  describe '#config_file' do
    it 'is the default RuboCop dotfile' do
      expect(subject.config_file).to eq('.rubocop.yml')
    end

    it 'can be overwritten via config options' do
      expect(subject.config_file(rubocop_config: '.custom.yml')).to eq(
        '.custom.yml')
    end

    it 'ignores blank rubocop_config values' do
      expect(subject.config_file(rubocop_config: nil)).to eq(
        '.rubocop.yml')

      expect(subject.config_file(rubocop_config: ' ')).to eq(
        '.rubocop.yml')
    end
  end

  def build_file(name, *lines)
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
