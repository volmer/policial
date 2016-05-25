# frozen_string_literal: true

require 'spec_helper'

describe Policial::StyleGuides::Ruby do
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
      file: '.rubocop.yml',
      content: custom_config.to_yaml
    )
  end

  describe '#violations_in_file' do
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
          'Style/StringLiterals' => { 'EnforcedStyle' => 'double_quotes' }
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
            'Style/StringLiterals' => {
              'Exclude' => ['lib/**/*', 'config/ext.rb']
            }
          }
        end

        it 'has no violations' do
          file = build_file('lib/test.rb', '"Awful code"')
          expect(subject.violations_in_file(file)).to be_empty

          file = build_file('config/ext.rb', '"Awful code"')
          expect(subject.violations_in_file(file)).to be_empty
        end
      end

      context 'when custom config inherits from a remote file' do
        let(:custom_config) do
          { 'inherit_from' => ['http://example.com/rubocop.yml'] }
        end

        it 'fetches and uses the remote config' do
          stub_request(:get, 'http://example.com/rubocop.yml').to_return(
            body: { 'Style/StringLiterals' => { 'Enabled' => false } }.to_yaml)
          file = build_file('app/models/ugly.rb', '"double quotes"')
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
        { 'Rails' => { 'Enabled' => true } }
      end

      it 'runs Rails cops' do
        file = build_file('app/models/ugly.rb', "puts 'my logs'")
        expect(subject.violations_in_file(file)).not_to be_empty
      end
    end

    context 'when custom config explicitly disables Rails cops' do
      let(:custom_config) do
        { 'Rails' => { 'Enabled' => false } }
      end

      it 'ignores Rails cops' do
        file = build_file('app/models/ugly.rb', "puts 'my logs'")
        expect(subject.violations_in_file(file)).to be_empty
      end
    end

    context 'when custom config requires external gems' do
      let(:custom_config) do
        { 'require' => 'rubocop-rspec' }
      end

      it 'ignores it' do
        file = build_file('spec/my_spec.rb', '@my_var = 1')
        expect(subject.violations_in_file(file)).to be_empty
      end
    end

    context 'when custom config inherits from local files' do
      let(:custom_config) do
        { 'inherit_from' => ['.rubocop-todo.yml'] }
      end

      it 'ignores it' do
        file = build_file('spec/my_spec.rb', '@my_var = 1')
        expect { subject.violations_in_file(file) }.not_to raise_error
      end
    end

    context 'when custom config inherits from a string instead of an array' do
      let(:custom_config) do
        { 'inherit_from' => '.rubocop-todo.yml' }
      end

      it 'ignores it' do
        file = build_file('spec/my_spec.rb', '@my_var = 1')
        expect { subject.violations_in_file(file) }.not_to raise_error
      end
    end

    context 'when custom config inherits from a gem' do
      let(:custom_config) do
        { 'inherit_gem' => { 'my_gem' => '.rubocop.yml' } }
      end

      it 'ignores it' do
        file = build_file('spec/my_spec.rb', '@my_var = 1')
        expect { subject.violations_in_file(file) }.not_to raise_error
      end
    end

    it 'respects RuboCop comments' do
      file = build_file(
        'test.rb',
        '# rubocop:disable Style/StringLiterals',
        '"I like it!"',
        '# rubocop:enable Style/StringLiterals'
      )
      expect(subject.violations_in_file(file)).to be_empty

      file = build_file(
        'test.rb', '"I like it!" # rubocop:disable Style/StringLiterals')
      expect(subject.violations_in_file(file)).to be_empty
    end
  end

  describe '#filename_patterns' do
    context 'when custom config has Include' do
      let(:custom_config) do
        { 'AllCops' => { 'Include' => ['fastlane/Fastfile'] } }
      end

      it 'includes AllCops Include in filename_patterns' do
        patterns = [/.+\.rb\z/, %r{fastlane/Fastfile}]
        expect(subject.filename_patterns).to match(patterns)
      end

      it 'matches Ruby files' do
        expect(subject.filename_patterns.first).to match('my_file.rb')
        expect(subject.filename_patterns.first).to match('app/base.rb')
        expect(subject.filename_patterns.first).not_to match('my_file.erb')
        expect(subject.filename_patterns.last).to match('fastlane/Fastfile')
      end
    end

    context 'when custom config is nil' do
      it 'matches Ruby files' do
        expect(subject.filename_patterns.first).to match('my_file.rb')
        expect(subject.filename_patterns.first).to match('app/base.rb')
        expect(subject.filename_patterns.first).not_to match('my_file.erb')
      end
    end
  end

  describe '#default_config_file' do
    it 'is .rubocop.yml' do
      expect(subject.default_config_file).to eq('.rubocop.yml')
    end
  end

  describe '#exclude_file?' do
    it 'is false when there is no custom config' do
      expect(subject.exclude_file?('app/file.rb')).to be false
    end

    context 'when custom config excludes the file' do
      let(:custom_config) do
        { 'AllCops' => { 'Exclude' => ['app/file.rb'] } }
      end

      it 'is true' do
        expect(subject.exclude_file?('app/file.rb')).to be true
      end
    end

    context 'when custom config does not exclude the file' do
      let(:custom_config) do
        { 'AllCops' => { 'Exclude' => ['app/other_file.rb'] } }
      end

      it 'is true' do
        expect(subject.exclude_file?('app/file.rb')).to be false
      end
    end
  end

  def build_file(name, *lines)
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
