require 'spec_helper'

describe Policial::Payload do
  subject { described_class.new(data) }

  describe '#changed_files' do
    context 'with pull_request data' do
      let(:data) do
        File.read('spec/support/fixtures/pull_request_opened_event.json')
      end

      it 'returns number of changed files' do
        expect(subject.changed_files).to eq 1
      end
    end

    context 'with no pull_request data' do
      let(:data) { '{}' }

      it 'returns zero' do
        expect(subject.changed_files).to be_zero
      end
    end
  end

  describe '#head_sha' do
    context 'with pull_request data' do
      let(:data) do
        { 'pull_request' => { 'head' => { 'sha' => 'abc123' } } }
      end

      it 'returns sha' do
        expect(subject.head_sha).to eq 'abc123'
      end
    end

    context 'with no pull_request data' do
      let(:data) do
        { 'some_key' => 'something' }
      end

      it 'returns nil' do
        expect(subject.head_sha).to be_nil
      end
    end
  end

  describe '#data' do
    let(:data) do
      { one: 1 }
    end

    it 'returns data' do
      expect(subject.data).to eq data
    end
  end

  describe '#pull_request_number' do
    let(:data) do
      { 'number' => 2 }
    end

    it 'returns the pull request number' do
      expect(subject.pull_request_number).to eq 2
    end
  end
end
