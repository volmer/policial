require 'spec_helper'

describe Policial::GitHubApi do
  let(:api) { Policial::GitHubApi.new }

  describe '#pull_request_files' do
    it 'returns changed files in a pull request' do
      pull_request = double(:pull_request, full_repo_name: 'volmer/cerberus')
      pr_number = 123

      stub_pull_request_files_request(pull_request.full_repo_name, pr_number)

      files = api.pull_request_files(pull_request.full_repo_name, pr_number)

      expect(files.size).to eq(1)
      expect(files.first.filename).to eq 'config/unicorn.rb'
    end
  end

  describe '#create_pull_request_comment' do
    it 'adds comment to GitHub' do
      repo = 'test/repo'
      pull_request_number = 2
      comment = 'test comment'
      commit_sha = 'commitsha'
      file = 'test.rb'
      patch_position = 123

      request = stub_comment_request(
        comment,
        repo: repo,
        pull_request: pull_request_number,
        commit: commit_sha,
        line: patch_position,
        file: file
      )

      api.create_pull_request_comment(
        repo,
        pull_request_number,
        comment,
        commit_sha,
        file,
        patch_position
      )

      expect(request).to have_been_requested
    end
  end

  describe '#pull_request_comments' do
    it 'returns comments added to pull request' do
      pull_request = double(:pull_request, full_repo_name: 'volmer/cerberus')
      pull_request_id = 253
      expected_comment = "inline if's and while's are not violations?"
      stub_pull_request_comments_request(
        pull_request.full_repo_name,
        pull_request_id
      )

      comments = api.pull_request_comments(
        pull_request.full_repo_name,
        pull_request_id
      )

      expect(comments.size).to eq(4)
      expect(comments.first.body).to eq expected_comment
    end
  end
end
