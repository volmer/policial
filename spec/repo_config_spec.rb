require 'spec_helper'

describe Policial::RepoConfig do
  subject { described_class.new(commit) }
  let(:commit) { Policial::Commit.new('volmer/cerberus', 'commitsha') }
  let(:guide) { double('guide', config_file: '.policial.yml') }

  describe '#enabled_for?' do
    it 'returns true for StyleGuides::Ruby' do
      expect(subject).to be_enabled_for(Policial::StyleGuides::Ruby)
    end
  end

  describe '#for' do
    it 'is a Hash with the config from the file found on the repo' do
      content_request_returns('DoubleQuotes: enabled')

      expect(subject.for(guide)).to eq('DoubleQuotes' => 'enabled')
    end

    it 'is empty if style guide class does not use a config file' do
      guide = double('guide', config_file: nil)

      expect(subject.for(guide)).to eq({})
    end

    it 'is empty if the retrieved config file is invalid' do
      content_request_returns('###')

      expect(subject.for(guide)).to eq({})
    end
  end

  def content_request_returns(content)
    stub_contents_request_with_content(
      'volmer/cerberus',
      sha: 'commitsha',
      file: '.policial.yml',
      content: content
    )
  end
end
