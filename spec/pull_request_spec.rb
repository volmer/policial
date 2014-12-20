require 'spec_helper'

describe Policial::PullRequest do
  subject { described_class.new('volmer/cerberus', 45, 'commitsha') }

  describe '#repo' do
    it 'returns the repo name' do
      expect(subject.repo).to eq('volmer/cerberus')
    end
  end

  describe '#number' do
    it 'returns the pull request number' do
      expect(subject.number).to eq(45)
    end
  end

  describe '#head_commit' do
    it 'contains the head SHA' do
      expect(subject.head_commit.sha).to eq('commitsha')
    end

    it 'contains the repo name' do
      expect(subject.head_commit.repo).to eq('volmer/cerberus')
    end
  end

  describe '#comments' do
    it 'returns comments on pull request' do
      stub_pull_request_comments_request('volmer/cerberus', 45)

      expect(subject.comments.size).to eq(4)
      expect(subject.comments.first.body).to eq('Single quotes please.')
    end
  end

  describe '#files' do
    it 'returns files on pull request' do
      stub_pull_request_files_request('volmer/cerberus', 45)

      expect(subject.files.size).to eq(1)
      expect(subject.files.first.filename).to eq('config/unicorn.rb')
    end
  end
end
