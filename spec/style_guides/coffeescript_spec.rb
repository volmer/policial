# frozen_string_literal: true

require 'spec_helper'

describe Policial::StyleGuides::CoffeeScript do
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
      file: 'coffeelint.json',
      content: custom_config.to_json
    )
  end

  describe '#violations_in_file' do
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

  describe '#filename_pattern' do
    it 'matches CoffeeScript files' do
      expect(subject.filename_pattern).to match('my_file.coffee')
      expect(subject.filename_pattern).to match('app/script.coffee')
      expect(subject.filename_pattern).not_to match('my_file.coffee.erb')
    end
  end

  describe '#default_config_file' do
    it 'is coffeelint.json' do
      expect(subject.default_config_file).to eq('coffeelint.json')
    end
  end

  describe '#exclude_file?' do
    it 'is false' do
      expect(subject.exclude_file?('filename')).to eq(false)
    end
  end

  def build_file(name, *lines)
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
