# frozen_string_literal: true

require 'spec_helper'

describe Policial::Linters::CoffeeScript do
  subject { described_class.new }

  let(:custom_config) { nil }

  let(:config_loader) do
    Policial::ConfigLoader.new(
      Policial::Commit.new('volmer/cerberus', 'commitsha', Octokit)
    )
  end

  before do
    stub_contents_request_with_content(
      'volmer/cerberus',
      sha: 'commitsha',
      file: 'coffeelint.json',
      content: custom_config.to_json
    )
  end

  describe '#violations' do
    it 'returns one violation per lint' do
      file_content = [
        'foo: =>',
        '  "bar"',
        'class boaConstrictor'
      ]
      file = build_file('test.coffee', file_content)

      violations = subject.violations(file, config_loader)

      expect(violations.count).to eq(2)

      expect(violations[0].filename).to eq('test.coffee')
      expect(violations[0].line_range).to eq(1..1)
      expect(violations[0].message).to eq(
        'Unnecessary fat arrow'
      )

      expect(violations[1].filename).to eq('test.coffee')
      expect(violations[1].line_range).to eq(3..3)
      expect(violations[1].message).to eq(
        'Class name should be UpperCamelCased'
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
        violations = subject.violations(file, config_loader)

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

      it 'detects offenses to the custom linter' do
        file_content = ['foo: =>', '  "baz"']
        file = build_file('test.coffee', file_content)

        violations = subject.violations(file, config_loader)

        expect(violations.count).to eq(2)
        expect(violations[0].message).to eq('Unnecessary fat arrow')
        expect(violations[1].message).to eq(
          'Unnecessary double quotes are forbidden'
        )
      end
    end

    it 'ignores non .coffee files' do
      file = build_file('my_file.coffee.erb', '<html>', '</html>')

      expect(
        subject.violations(file, config_loader)
      ).to be_empty
    end

    context 'with custom config file name' do
      subject { described_class.new(config_file: 'my_custom_coffeelint.json') }

      before do
        stub_contents_request_with_content(
          'volmer/cerberus',
          sha: 'commitsha',
          file: 'my_custom_coffeelint.json',
          content: {
            'no_unnecessary_double_quotes' => {
              'level' => 'error'
            }
          }.to_json
        )
      end

      it 'detects offenses based on custom file' do
        file = build_file('test.coffee', 'foo: =>', '  "baz"')

        violations = subject.violations(file, config_loader)

        expect(violations.count).to eq(2)
        expect(violations[0].message).to eq('Unnecessary fat arrow')
        expect(violations[1].message).to eq(
          'Unnecessary double quotes are forbidden'
        )
      end
    end
  end

  def build_file(name, *lines)
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
