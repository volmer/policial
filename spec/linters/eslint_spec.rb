# frozen_string_literal: true

require 'spec_helper'
require 'policial/linters/eslint'

describe Policial::Linters::ESLint do
  subject { described_class.new }

  let(:custom_config) { nil }

  let(:commit) do
    Policial::Commit.new('volmer/cerberus', 'commitsha', 'my-branch', Octokit)
  end

  before do
    stub_contents_request_with_content(
      'volmer/cerberus',
      sha: 'commitsha',
      file: '.eslintrc.json',
      content: custom_config.to_json
    )
  end

  describe '#violations_in_file' do
    it 'returns one violation per lint' do
      file_content = [
        'var foo = function (bar) {',
        '  return "foobar;"',
        '}'
      ]
      file = build_file('test.js', file_content)

      violations = subject.violations(file, commit)

      expect(violations.count).to eq(1)
      expect(violations[0].filename).to eq('test.js')
      expect(violations[0].line_range).to eq(1..1)
      expect(violations[0].linter).to eq('strict')
      expect(violations[0].message).to eq(
        "Use the function form of 'use strict'."
      )
    end

    it 'reports syntax errors' do
      file = build_file('test.js', "import React from 'react';")
      violations = subject.violations(file, commit)

      expect(violations.count).to eq(1)
      expect(violations.first.filename).to eq('test.js')
      expect(violations.first.line_range).to eq(1..1)
      expect(violations.first.linter).to eq('undefined')
      expect(violations.first.message).to eq(
        "Parsing error: The keyword 'import' is reserved"
      )
    end

    context 'with valid file' do
      it 'has no violations' do
        file_content = [
          'function foo (bar) {',
          "  'use strict';",
          "  console.log('bar')",
          '}'
        ]
        file = build_file('test.js', file_content)
        expect(subject.violations(file, commit)).to be_empty
      end
    end

    context 'with custom configuration' do
      let(:custom_config) do
        {
          'rules' => {
            'no-plusplus' => 2
          }
        }
      end

      it 'detects offenses to the custom linter' do
        file_content = [
          'var foo = 1;',
          'foo++;'
        ]
        file = build_file('test.js', file_content)

        violations = subject.violations(file, commit)

        expect(violations.count).to eq(1)
        expect(violations[0].message).to eq("Unary operator '++' used.")
      end
    end

    context 'with invalid custom configuration' do
      let(:custom_config) do
        { 'parser' => 'babel-eslint' }
      end

      it 'raises a linter error' do
        file = build_file('test.js', ['var foo = 1;'])

        expect { subject.violations(file, commit) }
          .to raise_error(
            Policial::LinterError, "Cannot find module 'babel-eslint'"
          )
      end
    end

    context 'when ExecJS crashes' do
      before do
        allow(Eslintrb)
          .to receive(:lint)
          .and_raise(ExecJS::ProgramError, 'boom!')
      end

      it 'raises a linter error' do
        file = build_file('test.js', ['var foo = 1;'])

        expect { subject.violations(file, commit) }
          .to raise_error(
            Policial::LinterError,
            'ESLint has crashed because of ExecJS::ProgramError: boom!'
          )
      end
    end

    it 'ignores non JavaScript files' do
      file = build_file('my_file.coffee', 'var foo = 1;')
      expect(subject.violations(file, commit)).to be_empty
    end

    context 'with custom config file name' do
      subject { described_class.new(config_file: 'custom_config.json') }

      before do
        stub_contents_request_with_content(
          'volmer/cerberus',
          sha: 'commitsha',
          file: 'custom_config.json',
          content: {
            'rules' => {
              'no-plusplus' => 2
            }
          }.to_json
        )
      end

      it 'detects offenses' do
        file_content = [
          'var foo = 1;',
          'foo++;'
        ]
        file = build_file('test.js', file_content)

        violations = subject.violations(file, commit)

        expect(violations.count).to eq(1)
        expect(violations[0].message).to eq("Unary operator '++' used.")
      end
    end
  end

  describe '#correct' do
    it 'is nil' do
      file = build_file('test.js', 'foo')
      expect(subject.correct(file, commit)).to be nil
    end
  end

  def build_file(name, *lines)
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
