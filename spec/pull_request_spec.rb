# frozen_string_literal: true

require 'spec_helper'

describe Policial::PullRequest do
  subject do
    described_class.new(
      repo: 'volmer/cerberus',
      number:  45,
      head_sha: 'commitsha',
      head_ref: 'my-branch',
      user: 'volmerius',
      github_client: Octokit
    )
  end

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

  describe '#user' do
    it 'returns the pull request user' do
      expect(subject.user).to eq('volmerius')
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

  describe '#files' do
    it 'returns files on pull request' do
      stub_pull_request_files_request('volmer/cerberus', 45)

      expect(subject.files.size).to eq(1)
      expect(subject.files.first.filename).to eq('config/unicorn.rb')
    end
  end
end
