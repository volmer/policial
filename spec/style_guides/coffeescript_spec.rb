require 'spec_helper'

describe Policial::StyleGuides::Coffeescript do
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
    it 'detects offenses to the CoffeeScript Style Guide' do
      file = build_file('test.coffee', 'foo: -> "bar"')
      violations = subject.violations_in_file(file)

      expect(violations.count).to eq(1)
      expect(violations.first.filename).to eq('test.coffee')
      expect(violations.first.line_number).to eq(1)
      expect(violations.first.message).to eq(
        'Unnecessary double quotes are forbidden'
      )
    end

    it 'returns one violation per lint' do
      file_content = [
        'foo: => ',
        '  debugger',
        '  "bar"'
      ]
      file = build_file('test.coffee', file_content)

      violations = subject.violations_in_file(file)

      expect(violations.count).to eq(3)

      expect(violations[0].filename).to eq('test.coffee')
      expect(violations[0].line_number).to eq(1)
      expect(violations[0].message).to eq(
        'Line ends with trailing whitespace'
      )

      expect(violations[1].filename).to eq('test.coffee')
      expect(violations[1].line_number).to eq(2)
      expect(violations[1].message).to eq(
        'Found debugging code'
      )

      expect(violations[2].filename).to eq('test.coffee')
      expect(violations[2].line_number).to eq(3)
      expect(violations[2].message).to eq(
        'Unnecessary double quotes are forbidden'
      )
    end

    context 'with valid file' do
      it 'has no violations' do
        file_content = [
          'foo: ->',
          '  console.log(\'foo\')',
          '  \'bar\''
        ]
        file = build_file('test.coffee', file_content)
        violations = subject.violations_in_file(file)

        expect(violations.count).to eq(0)
      end
    end
  end

  describe '#coffeelint_config_file' do
    it 'is the default Coffeelint json file' do
      expect(subject.coffeelint_config_file).to eq('coffeelint.json')
    end
  end

  def build_file(name, *lines)
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
