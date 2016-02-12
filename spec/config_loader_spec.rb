# frozen_string_literal: true

require 'spec_helper'

describe Policial::ConfigLoader do
  subject { described_class.new(commit) }
  let(:commit) { Policial::Commit.new('volmer/cerberus', 'commitsha', Octokit) }

  describe '#raw' do
    it 'is the content of the given file' do
      content_request_returns('policial.yml', 'DoubleQuotes: enabled')

      expect(subject.raw('policial.yml')).to eq('DoubleQuotes: enabled')
    end

    it 'is blank if filename is blank' do
      expect(subject.raw(nil)).to eq('')
      expect(subject.raw('')).to eq('')
      expect(subject.raw(' ')).to eq('')
    end

    it 'is blank if the retrieved config file is blank' do
      content_request_returns('policial.yml', '')

      expect(subject.raw('policial.yml')).to eq('')
    end
  end

  describe '#yaml' do
    it 'is a Hash with the config from the file found on the repo' do
      content_request_returns('policial.yml', 'DoubleQuotes: enabled')

      expect(subject.yaml('policial.yml')).to eq('DoubleQuotes' => 'enabled')
    end

    it 'is empty if filename is blank' do
      expect(subject.yaml(nil)).to eq({})
      expect(subject.yaml('')).to eq({})
      expect(subject.yaml(' ')).to eq({})
    end

    it 'is empty if the retrieved config file is invalid' do
      content_request_returns('policial.yml', '###')

      expect(subject.yaml('policial.yml')).to eq({})
    end

    it 'is empty if the retrieved config file is blank' do
      content_request_returns('policial.yml', '')

      expect(subject.yaml('policial.yml')).to eq({})
    end
  end

  describe '#json' do
    it 'is a Hash with the config from the file found on the repo' do
      content_request_returns('policial.json', '{ "DoubleQuotes": "enabled" }')

      expect(subject.json('policial.json')).to eq('DoubleQuotes' => 'enabled')
    end

    it 'is empty if filename is blank' do
      expect(subject.json(nil)).to eq({})
      expect(subject.json('')).to eq({})
      expect(subject.json(' ')).to eq({})
    end

    it 'is empty if the retrieved config file is invalid' do
      content_request_returns('policial.json', '###')

      expect(subject.json('policial.json')).to eq({})
    end

    it 'is empty if the retrieved config file is blank' do
      content_request_returns('policial.json', '')

      expect(subject.json('policial.json')).to eq({})
    end
  end

  private

  def content_request_returns(file, content)
    stub_contents_request_with_content(
      'volmer/cerberus',
      sha: 'commitsha',
      file: file,
      content: content
    )
  end
end
