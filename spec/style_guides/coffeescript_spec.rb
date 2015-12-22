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

  describe '#violations_in_file' do
    before do
      stub_contents_request_with_content(
        'volmer/cerberus',
        sha: 'commitsha',
        file: 'coffeelint.json',
        content: custom_config.to_json
      )
    end

    it 'returns one violation per lint' do
      file_content = [
        'foo: =>',
        '  debugger',
        '  "bar"'
      ]
      file = build_file('test.coffee', file_content)

      violations = subject.violations_in_file(file)

      expect(violations.count).to eq(2)

      expect(violations[0].filename).to eq('test.coffee')
      expect(violations[0].line_number).to eq(1)
      expect(violations[0].message).to eq(
        'Unnecessary fat arrow'
      )

      expect(violations[1].filename).to eq('test.coffee')
      expect(violations[1].line_number).to eq(2)
      expect(violations[1].message).to eq(
        'Found debugging code'
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

    it 'ignores non .coffee files' do
      file = build_file('ugly.js', 'foo: -> "bar"')
      expect(subject.violations_in_file(file)).to be_empty
    end

    context 'with custom configuration' do
      let(:custom_config) do
        {
          'no_unnecessary_double_quotes' => {
            'level' => 'error'
          }
        }
      end

      it 'detects offenses to the custom style guide' do
        file_content = ['foo: =>', '  "baz"']
        file = build_file('test.coffee', file_content)

        violations = subject.violations_in_file(file)

        expect(violations.count).to eq(2)
        expect(violations[0].message).to eq('Unnecessary fat arrow')
        expect(violations[1].message).to eq(
          'Unnecessary double quotes are forbidden'
        )
      end
    end
  end

  describe '#config_file' do
    it 'is the default Coffeelint json file' do
      expect(subject.config_file).to eq('coffeelint.json')
    end
  end

  def build_file(name, *lines)
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
