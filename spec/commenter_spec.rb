require 'spec_helper'

describe Policial::Commenter do
  subject { described_class.new(pull_request) }
  let(:pull_request) { Policial::PullRequest.new('volmer/cerberus', 2, 'sha') }

  describe '#comment_violation' do
    it 'adds a comment regarding the given violation to the pull request' do
      violation = Policial::Violation.new(
        double('file', filename: 'lib/octokit.rb', line_at: ''),
        42,
        'violation_1'
      )
      violation.add_messages(['violation_2'])

      expected_params = [
        'volmer/cerberus',
        2,
        'violation_1<br/>violation_2',
        'sha',
        'lib/octokit.rb',
        42
      ]

      expect_any_instance_of(Policial::GithubApi)
        .to receive(:create_pull_request_comment)
        .with(*expected_params).and_return(true)

      expect(subject.comment_violation(violation)).to be true
    end
  end
end
