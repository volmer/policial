require 'spec_helper'

describe Policial::PullRequest do
  subject { described_class.new(payload) }

  describe '#opened?' do
    context 'when payload action is opened' do
      let(:payload) { payload_stub(action: 'opened') }

      it 'returns true' do
        expect(subject).to be_opened
      end
    end

    context 'when payload action is not opened' do
      let(:payload) { payload_stub(action: 'notopened') }

      it 'returns false' do
        expect(subject).not_to be_opened
      end
    end
  end

  describe '#synchronize?' do
    context 'when payload action is synchronize' do
      let(:payload) { payload_stub(action: 'synchronize') }

      it 'returns true' do
        expect(subject).to be_synchronize
      end
    end

    context 'when payload action is not synchronize' do
      let(:payload) { payload_stub(action: 'notsynchronize') }

      it 'returns false' do
        expect(subject).not_to be_synchronize
      end
    end
  end

  describe '#comments' do
    it 'returns comments on pull request' do
      filename = 'spec/models/style_guide_spec.rb'
      comment = double(:comment, position: 7, path: filename)
      github = double(:github, pull_request_comments: [comment])
      pull_request = pull_request_stub(github)

      comments = pull_request.comments

      expect(comments.size).to eq(1)
      expect(comments).to match_array([comment])
    end
  end

  describe '#comment_on_violation' do
    it 'posts a comment to GitHub' do
      payload = payload_stub
      github = double(:github_client, add_pull_request_comment: nil)
      pull_request = pull_request_stub(github, payload)
      violation = violation_stub
      commit = double('Commit')
      allow(Policial::Commit).to receive(:new).and_return(commit)

      pull_request.comment_on_violation(violation)

      expect(github).to have_received(:add_pull_request_comment).with(
        pull_request_number: payload.pull_request_number,
        commit: commit,
        comment: violation.messages.first,
        filename: violation.filename,
        patch_position: violation.patch_position
      )
    end
  end

  def violation_stub(options = {})
    defaults =  {
      messages: ['A comment'],
      filename: 'test.rb',
      patch_position: 123
    }
    double('Violation', defaults.merge(options))
  end

  def payload_stub(options = {})
    defaults = {
      full_repo_name: 'org/repo',
      head_sha: '1234abcd',
      pull_request_number: 5
    }
    double('Payload', defaults.merge(options))
  end

  def pull_request_stub(api, payload = payload_stub)
    allow(Policial::GithubApi).to receive(:new).and_return(api)
    described_class.new(payload)
  end
end
