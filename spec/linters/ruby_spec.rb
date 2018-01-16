# frozen_string_literal: true

require 'spec_helper'

describe Policial::Linters::Ruby do
  let(:linter) do
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

  describe '#autocorrect' do
    let(:file) { build_file('test.rb', *lines) }
    let(:violations) { linter.violations_in_file(file) }
    subject do
      linter
        .autocorrect(file)
        .sub("# frozen_string_literal: true\n\n", '')
        .sub(/\n\z/, '')
    end

    context 'when line has changed' do
      let(:lines) { [build_line('"I am naughty"', changed: true)] }

      it { expect(subject).to eq "'I am naughty'" }
    end

    context 'when line has not changed' do
      let(:lines) { [build_line('"I am naughty"', changed: false)] }

      it { expect(subject).to eq '"I am naughty"' }
    end

    context 'when a line in the violation range has changed' do
      let(:lines) do
        [
          build_line('<<~BLOCK', changed: false),
          build_line('    foo', changed: false),
          build_line('    bar', changed: true),
          build_line('BLOCK', changed: false)
        ]
      end

      it { expect(violations.size).to eq(1) }
      it { expect(subject).to eq <<~EXPECTED.strip }
        <<~BLOCK
          foo
          bar
        BLOCK
      EXPECTED
    end

    context 'when multiple offenses are detected but '\
        'some are on unchanged lines' do
      let(:lines) do
        [
          build_line('', changed: false),
          build_line('<<~BLOCK', changed: false),
          build_line('    foo', changed: false),
          build_line('    bar', changed: true),
          build_line('BLOCK', changed: false),
          build_line('', changed: false)
        ]
      end

      it { expect(violations.size).to eq(3) }
      it do
        expect(violations.map(&:linter)).to \
          eq(['Layout/EmptyLines', 'Layout/IndentHeredoc',
              'Layout/TrailingBlankLines'])
      end
      it { expect(subject).to eq <<~EXPECTED }

        <<~BLOCK
          foo
          bar
        BLOCK
      EXPECTED
    end

    context 'when a correction loop occurs' do
      let(:lines) { [build_line('"I am naughty"', changed: true)] }

      before do
        naughty = file.content
        nice = naughty.sub('naughty', 'nice')

        allow(RuboCop::Cop::Corrector)
          .to receive(:new)
          .and_return(
            # rubocop's Team object also creates
            # a corrector for each correction loop
            double('corrector', corrections: [], rewrite: nice),
            double('corrector', corrections: [], rewrite: nice),
            double('corrector', corrections: [], rewrite: naughty),
            double('corrector', corrections: [], rewrite: naughty)
          )
      end

      it 'raises an error' do
        expect { subject }.to raise_error(
          Policial::Linters::Ruby::InfiniteCorrectionLoop,
          'Detected correction loop for test.rb'
        )
      end
    end

    context 'when correction is not finished after many loops' do
      let(:lines) { [build_line('"I am naughty"', changed: true)] }

      before do
        allow(RuboCop::Cop::Corrector)
          .to receive(:new)
          .and_return(
            *Array.new(400) do |n|
              content = file.content.sub('naughty', 'z' * n)
              double('corrector', corrections: [], rewrite: content)
            end
          )
      end

      it 'raises an error' do
        expect { subject }.to raise_error(
          Policial::Linters::Ruby::InfiniteCorrectionLoop,
          'Stopping after 201 iterations for test.rb'
        )
      end
    end
  end

  describe '#violations_in_file' do
    subject { linter }

    it 'detects offenses to the Ruby community Style Guide' do
      file = build_file('test.rb', '"I am naughty"')
      violations = subject.violations_in_file(file)

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
        '    foo',
        '    bar',
        'BLOCK'
      ]
      file = build_file('test.rb', *file_content)

      violations = subject.violations_in_file(file)

      expect(violations.count).to eq(1)
      expect(violations[0].line_range).to eq(4..6)
      expect(violations[0].linter).to eq('Layout/IndentHeredoc')
      expect(violations[0].message).to eq(
        'Layout/IndentHeredoc: Use 2 spaces for indentation in a '\
        'heredoc by using `<<~` instead of `<<~`.'
      )
    end

    it 'returns one violation per offense' do
      file_content =
        ['{first_line: :violates }', '"second too!".to_sym', "'third ok'"]
      file = build_file('test.rb', *file_content)

      violations = subject.violations_in_file(file)

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
        violations = subject.violations_in_file(file)

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
            body: { 'Style/StringLiterals' => { 'Enabled' => false } }.to_yaml
          )
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

    context 'when custom config requires a file that can be loaded' do
      let(:custom_config) do
        { 'require' => './spec/support/custom_cop.rb' }
      end

      it 'loads it' do
        file = build_file('spec/my_spec.rb', '@fuck = true')
        violation = subject.violations_in_file(file).first
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
        expect { subject.violations_in_file(file) }
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
        expect { subject.violations_in_file(file) }
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
        'test.rb', '"I like it!" # rubocop:disable Style/StringLiterals'
      )
      expect(subject.violations_in_file(file)).to be_empty
    end

    context 'when custom config defines Cop Details' do
      let(:custom_config) do
        { 'Style/StringLiterals' => { 'Details' => 'Get rid of those quotes' } }
      end

      it 'uses the details in the violation message' do
        file = build_file('test.rb', '"I am naughty"')

        violations = subject.violations_in_file(file)

        expect(violations.first.message).to eq(
          "Style/StringLiterals: Prefer single-quoted strings when you don't "\
          'need string interpolation or special symbols. Get rid of those '\
          'quotes'
        )
      end
    end
  end

  describe '#include_file?' do
    subject { linter }

    it 'includes Ruby files' do
      expect(subject.include_file?('app/file.rb')).to be true
      expect(subject.include_file?('another.rb')).to be true
    end

    it 'includes Rake files' do
      expect(subject.include_file?('lib/task.rake')).to be true
    end

    it 'does not include ERB files' do
      expect(subject.include_file?('app/view.erb')).to be false
    end

    context 'when custom config has Include' do
      let(:custom_config) do
        { 'AllCops' => { 'Include' => ['fastlane/Fastfile'] } }
      end

      it 'matches Ruby files' do
        expect(subject.include_file?('my_file.rb')).to be true
        expect(subject.include_file?('app/base.rb')).to be true
        expect(subject.include_file?('my_file.erb')).to be false
        expect(subject.include_file?('fastlane/Fastfile')).to be true
      end
    end

    context 'when custom config excludes the file' do
      let(:custom_config) do
        { 'AllCops' => { 'Exclude' => ['app/file.rb'] } }
      end

      it 'is false' do
        expect(subject.include_file?('app/file.rb')).to be false
      end
    end
  end

  describe '#default_config_file' do
    subject { linter }

    it 'is .rubocop.yml' do
      expect(subject.default_config_file).to eq('.rubocop.yml')
    end
  end

  def build_file(name, *lines)
    lines = lines.unshift('# frozen_string_literal: true', '')
    lines.map! { |line| line.is_a?(String) ? build_line(line) : line }
    file = double(
      'file',
      filename: name,
      content: lines.map(&:content).join("\n") + "\n"
    )
    allow(file).to receive(:line_at) { |n| lines[n - 1] }
    file
  end

  def build_line(content, changed: false)
    double('line', content: content, changed?: changed)
  end
end
