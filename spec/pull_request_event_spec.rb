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
  end

  describe '#head_sha' do
    it 'returns the payload action' do
      expect(subject.action).to eq('opened')
    end
  end

  describe '#payload' do
    it 'returns payload' do
      expect(subject.payload).to eq(payload)
    end
  end
end
