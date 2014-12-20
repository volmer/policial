require 'spec_helper'

describe Policial::Commenter do
  subject { described_class.new(pull_request) }
  let(:pull_request) do
    Policial::PullRequest.new(
      repo: 'volmer/cerberus', number: 2, head_sha: 'sha'
    )
  end

  describe '#comment_violation' do
    it 'adds a comment regarding the given violation to the pull request' do
      violation = Policial::Violation.new(
        double('file', filename: 'lib/octokit.rb', line_at: ''),
        42,
        'violation_1'
      )
      violation.add_messages(['violation_2'])

      request = stub_comment_request(
        'violation_1<br/>violation_2',
        repo: 'volmer/cerberus',
        pull_request: 2,
        commit: 'sha',
        file: 'lib/octokit.rb',
        line: 42
      )

      subject.comment_violation(violation)

      expect(request).to have_been_requested
    end
  end
end
