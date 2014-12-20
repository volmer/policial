require 'spec_helper'

describe Policial::PullRequestEvent do
  subject { described_class.new(payload) }

  let(:payload) do
    JSON.parse(
      File.read('spec/support/fixtures/pull_request_opened_event.json')
    )
  end

  describe '#pull_request' do
    it 'returns a pull request based on the payload' do
      pull_request = subject.pull_request

      expect(pull_request.number).to eq(2)
      expect(pull_request.repo).to eq('volmer/cerberus')
      expect(pull_request.head_commit.sha).to eq(
        '498b81cd038f8a3ac02f035a8537b7ddcff38a81'
      )
      expect(pull_request.user).to eq('volmerius')
    end

    context 'when payload is invalid' do
      let(:payload) { 'not_a_valid_payload' }

      it 'is nil' do
        expect(subject.pull_request).to be_nil
      end
    end
  end

  describe '#should_investigate?' do
    it 'is true if the pull request was opened' do
      expect(subject.should_investigate?).to be true
    end

    it 'is true if the pull request was synchronized' do
      subject.payload['action'] = 'synchronize'

      expect(subject.should_investigate?).to be true
    end

    it 'is false if the pull request was neither opened or synchronized' do
      subject.payload['action'] = 'closed'

      expect(subject.should_investigate?).to be false
    end

    context 'when payload is invalid' do
      let(:payload) { 'not_a_valid_payload' }

      it 'is false' do
        expect(subject.should_investigate?).to be false
      end
    end
  end

  describe '#payload' do
    it 'returns payload' do
      expect(subject.payload).to eq(payload)
    end
  end
end
