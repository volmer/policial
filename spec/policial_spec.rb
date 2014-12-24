require 'spec_helper'

describe Policial do
  describe '.octokit' do
    context 'when a custom client is set' do
      let(:custom_client) { Octokit::Client.new }
      before { subject.octokit = custom_client }
      after { subject.octokit = nil }

      it 'is the client' do
        expect(subject.octokit).to eq(custom_client)
      end
    end

    context 'when no client is set' do
      it 'is Octokit' do
        expect(subject.octokit).to eq(Octokit)
      end
    end
  end

  describe 'STYLE_GUIDES' do
    it 'includes Ruby' do
      expect(Policial::STYLE_GUIDES).to include(Policial::StyleGuides::Ruby)
    end
  end
end
