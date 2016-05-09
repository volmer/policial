# frozen_string_literal: true

require 'spec_helper'

describe Policial::StyleGuides::Erb do
  subject do
    described_class.new(
      Policial::ConfigLoader.new(
        Policial::Commit.new('volmer/cerberus', 'commitsha', Octokit)))
  end

  let(:custom_config) { nil }

  before do
    stub_contents_request_with_content(
      'volmer/cerberus',
      sha: 'commitsha',
      file: '.erb-lint.yml',
      content: custom_config.to_yaml
    )
  end

  describe '#violations_in_file' do
    context 'with custom configuration' do
      context 'with excluded files' do
      end
    end
    
    it 'is idempotent' do
    end
  end

  describe '#filename_pattern' do
    it 'matches ERB files' do
      expect(subject.filename_pattern).to match('my_file.html.erb')
      expect(subject.filename_pattern).to match('app/views/index.html.erb')
      expect(subject.filename_pattern).not_to match('my_file.erb')
      expect(subject.filename_pattern).not_to match('my_file.html')
      expect(subject.filename_pattern).not_to match('my_file.html.erb.scss')
    end
  end

  describe '#default_config_file' do
    it 'is .erb-lint.yml' do
      expect(subject.default_config_file).to eq('.erb-lint.yml')
    end
  end

  def build_file(name, *lines)
    file = double('file', filename: name, content: lines.join("\n") + "\n")
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
