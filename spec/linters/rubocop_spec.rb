# frozen_string_literal: true

require 'spec_helper'
require 'policial/linters/rubocop'

describe Policial::Linters::RuboCop do
  subject { described_class.new }

  let(:custom_config) { nil }

  let(:commit) do
    Policial::Commit.new('volmer/cerberus', 'commitsha', 'my-branch', Octokit)
  end

  before do
    stub_contents_request_with_content(
      'volmer/cerberus',
      sha: 'commitsha',
      file: '.rubocop.yml',
      content: custom_config.to_yaml
    )
  end

  describe '#violations_in_file' do
    it 'detects offenses to the RuboCop default Style Guide' do
      file = build_file('test.rb', '"I am naughty"')
      violations = subject.violations(file, commit)

      expect(violations.count).to eq(1)
      expect(violations.first.filename).to eq('test.rb')
      expect(violations.first.line_range).to eq(3..3)
      expect(violations.first.linter).to eq('Style/StringLiterals')
      expect(violations.first.message).to eq(
        "Style/StringLiterals: Prefer single-quoted strings when you don't "\
        'need string interpolation or special symbols.'
      )
    end

    it 'detects violations spanning multiple lines' do
      file_content = [
        '<<~BLOCK',
        '  foo',
        ' bar',
        'BLOCK'
      ]
      file = build_file('test.rb', file_content)

      violations = subject.violations(file, commit)

      expect(violations.count).to eq(1)
      expect(violations[0].line_range).to eq(4..6)
      expect(violations[0].linter).to eq('Layout/IndentHeredoc')
      expect(violations[0].message).to eq(
        'Layout/IndentHeredoc: Use 2 spaces for indentation in a heredoc.'
      )
    end

    it 'returns one violation per offense' do
      file_content =
        ['{first_line: :violates }', '"second too!".to_sym', "'third ok'"]
      file = build_file('test.rb', file_content)

      violations = subject.violations(file, commit)

      expect(violations.count).to eq(3)

      expect(violations[0].filename).to eq('test.rb')
      expect(violations[0].line_range).to eq(3..3)
      expect(violations[0].linter).to eq('Layout/SpaceInsideHashLiteralBraces')
      expect(violations[0].message).to eq(
        'Layout/SpaceInsideHashLiteralBraces: Space inside { missing.'
      )

      expect(violations[1].filename).to eq('test.rb')
      expect(violations[1].line_range).to eq(3..3)
      expect(violations[1].linter).to eq('Lint/Void')
      expect(violations[1].message).to eq(
        'Lint/Void: Literal `{first_line: :violates }` used in void context.'
      )

      expect(violations[2].filename).to eq('test.rb')
      expect(violations[2].line_range).to eq(4..4)
      expect(violations[2].linter).to eq('Style/StringLiterals')
      expect(violations[2].message).to eq(
        "Style/StringLiterals: Prefer single-quoted strings when you don't "\
        'need string interpolation or special symbols.'
      )
    end

    context 'with custom configuration' do
      let(:custom_config) do
        {
          'Style/StringLiterals' => { 'EnforcedStyle' => 'double_quotes' }
        }
      end

      it 'detects offenses to the custom linter' do
        file = build_file('test.rb', "'You do not like me'")
        violations = subject.violations(file, commit)

        expect(violations.count).to eq(1)
        expect(violations.first.filename).to eq('test.rb')
        expect(violations.first.line_range).to eq(3..3)
        expect(violations.first.linter).to eq('Style/StringLiterals')
        expect(violations.first.message).to eq(
          'Style/StringLiterals: Prefer double-quoted strings unless you need '\
          'single quotes to avoid extra backslashes for escaping.'
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
          expect(subject.violations(file, commit)).to be_empty

          file = build_file('config/ext.rb', '"Awful code"')
          expect(subject.violations(file, commit)).to be_empty
        end
      end

      context 'when custom config inherits from a remote file' do
        let(:custom_config) do
          { 'inherit_from' => ['http://example.com/rubocop.yml'] }
        end

        it 'fetches and uses the remote config' do
          stub_request(:get, 'http://example.com/rubocop.yml').to_return(
            body: { 'Style/StringLiterals' => { 'Enabled' => false } }.to_yaml
          )
          file = build_file('app/models/ugly.rb', '"double quotes"')
          expect(subject.violations(file, commit)).to be_empty
        end
      end
    end

    it 'ignores Rails cops by default' do
      file = build_file('app/models/ugly.rb', "puts 'my logs'")
      expect(subject.violations(file, commit)).to be_empty
    end

    context 'when custom config enables Rails cops' do
      let(:custom_config) do
        { 'Rails' => { 'Enabled' => true } }
      end

      it 'runs Rails cops' do
        file = build_file('app/models/ugly.rb', "puts 'my logs'")
        expect(subject.violations(file, commit)).not_to be_empty
      end
    end

    context 'when custom config explicitly disables Rails cops' do
      let(:custom_config) do
        { 'Rails' => { 'Enabled' => false } }
      end

      it 'ignores Rails cops' do
        file = build_file('app/models/ugly.rb', "puts 'my logs'")
        expect(subject.violations(file, commit)).to be_empty
      end
    end

    context 'when custom config requires a file that can be loaded' do
      let(:custom_config) do
        { 'require' => './spec/support/custom_cop.rb' }
      end

      it 'loads it' do
        file = build_file('spec/my_spec.rb', '@fuck = true')
        violation = subject.violations(file, commit).first
        expect(violation.linter).to eq('TestSupport/CustomCop')
        expect(violation.message).to eq('TestSupport/CustomCop: No swearwords!')
      end
    end

    context 'when custom config requires a file that cannot be loaded' do
      let(:custom_config) do
        { 'require' => './inexistent/file.rb' }
      end

      it 'raises Policial::ConfigDependencyError' do
        file = build_file('spec/my_spec.rb', '@my_var = 1')
        expect { subject.violations(file, commit) }
          .to raise_error(
            Policial::ConfigDependencyError,
            'Your RuboCop config .rubocop.yml requires inexistent/file.rb, '\
            'but it could not be loaded.'
          )
      end
    end

    context 'when custom config requires a gem that cannot be loaded' do
      let(:custom_config) do
        { 'require' => 'rubocop-rspec' }
      end

      it 'raises Policial::ConfigDependencyError' do
        file = build_file('spec/my_spec.rb', '@my_var = 1')
        expect { subject.violations(file, commit) }
          .to raise_error(
            Policial::ConfigDependencyError,
            'Your RuboCop config .rubocop.yml requires rubocop-rspec, '\
            'but it could not be loaded.'
          )
      end
    end

    context 'when custom config inherits from local files' do
      let(:custom_config) do
        { 'inherit_from' => ['.rubocop-todo.yml'] }
      end

      it 'ignores it' do
        file = build_file('spec/my_spec.rb', '@my_var = 1')
        expect { subject.violations(file, commit) }.not_to raise_error
      end
    end

    context 'when custom config inherits from a string instead of an array' do
      let(:custom_config) do
        { 'inherit_from' => '.rubocop-todo.yml' }
      end

      it 'ignores it' do
        file = build_file('spec/my_spec.rb', '@my_var = 1')
        expect { subject.violations(file, commit) }.not_to raise_error
      end
    end

    context 'when custom config inherits from a gem' do
      let(:custom_config) do
        { 'inherit_gem' => { 'my_gem' => '.rubocop.yml' } }
      end

      it 'ignores it' do
        file = build_file('spec/my_spec.rb', '@my_var = 1')
        expect { subject.violations(file, commit) }.not_to raise_error
      end
    end

    it 'respects RuboCop comments' do
      file = build_file(
        'test.rb',
        '# rubocop:disable Style/StringLiterals',
        '"I like it!"',
        '# rubocop:enable Style/StringLiterals'
      )
      expect(subject.violations(file, commit)).to be_empty

      file = build_file(
        'test.rb', '"I like it!" # rubocop:disable Style/StringLiterals'
      )
      expect(subject.violations(file, commit)).to be_empty
    end

    context 'when custom config defines Cop Details' do
      let(:custom_config) do
        { 'Style/StringLiterals' => { 'Details' => 'Get rid of those quotes' } }
      end

      it 'uses the details in the violation message' do
        file = build_file('test.rb', '"I am naughty"')

        violations = subject.violations(file, commit)

        expect(violations.first.message).to eq(
          "Style/StringLiterals: Prefer single-quoted strings when you don't "\
          'need string interpolation or special symbols. Get rid of those '\
          'quotes'
        )
      end
    end

    it 'inspects Rake files' do
      file = build_file('lib/task.rake', '"I am naughty"')
      violations = subject.violations(file, commit)

      expect(violations.count).to eq(1)
      expect(violations.first.filename).to eq('lib/task.rake')
      expect(violations.first.line_range).to eq(3..3)
      expect(violations.first.linter).to eq('Style/StringLiterals')
      expect(violations.first.message).to eq(
        "Style/StringLiterals: Prefer single-quoted strings when you don't "\
        'need string interpolation or special symbols.'
      )
    end

    it 'does not inspect ERB files' do
      file = build_file('app/view.erb', '<%= "I am naughty" %>')
      expect(subject.violations(file, commit)).to be_empty
    end

    context 'when custom config has Include' do
      let(:custom_config) do
        { 'AllCops' => { 'Include' => ['fastlane/Fastfile'] } }
      end

      it 'inspect the proper files' do
        file = build_file('fastlane/Fastfile', '"I am naughty"')
        violations = subject.violations(file, commit)

        expect(violations.count).to eq(1)
        expect(violations.first.filename).to eq('fastlane/Fastfile')
        expect(violations.first.line_range).to eq(3..3)
        expect(violations.first.linter).to eq('Style/StringLiterals')
        expect(violations.first.message).to eq(
          "Style/StringLiterals: Prefer single-quoted strings when you don't "\
          'need string interpolation or special symbols.'
        )
      end
    end

    context 'when custom config excludes the file' do
      let(:custom_config) do
        { 'AllCops' => { 'Exclude' => ['app/file.rb'] } }
      end

      it 'skips the file' do
        file = build_file('app/file.rb', '"I am naughty"')
        expect(subject.violations(file, commit)).to be_empty
      end
    end

    context 'with custom config file name' do
      subject { described_class.new(config_file: '.custom_rubocop.yml') }

      before do
        stub_contents_request_with_content(
          'volmer/cerberus',
          sha: 'commitsha',
          file: '.custom_rubocop.yml',
          content: {
            'Style/StringLiterals' => { 'EnforcedStyle' => 'double_quotes' }
          }.to_yaml
        )
      end

      it 'detects offenses to the custom linter' do
        file = build_file('test.rb', "'You do not like me'")
        violations = subject.violations(file, commit)

        expect(violations.count).to eq(1)
        expect(violations.first.filename).to eq('test.rb')
        expect(violations.first.line_range).to eq(3..3)
        expect(violations.first.linter).to eq('Style/StringLiterals')
        expect(violations.first.message).to eq(
          'Style/StringLiterals: Prefer double-quoted strings unless you need '\
          'single quotes to avoid extra backslashes for escaping.'
        )
      end
    end
  end

  describe '#correct' do
    it 'returns the file content with violations properly corrected' do
      file = build_file('test.rb', 'puts(:foo,)')
      expect(subject.correct(file, commit)).to include('puts(:foo)')
    end
  end

  def build_file(name, *lines)
    lines = lines.unshift('# frozen_string_literal: true', '')
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
