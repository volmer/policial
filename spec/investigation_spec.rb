require 'spec_helper'

describe Policial::Investigation do
  subject do
    described_class.new(
      Policial::PullRequestEvent.new(JSON.parse(
        File.read('spec/support/fixtures/pull_request_opened_event.json')
      )).pull_request
    )
  end

  describe '#run' do
    it 'finds all violations present in the pull request' do
      stub_pull_request_files_request('volmer/cerberus', 2)
      stub_contents_request(
        repo: 'volmer/cerberus',
        sha: '498b81cd038f8a3ac02f035a8537b7ddcff38a81',
        file: '.rubocop.yml',
        fixture: 'config_contents.json'
      )
      stub_contents_request(
        repo: 'volmer/cerberus',
        sha: '498b81cd038f8a3ac02f035a8537b7ddcff38a81',
        file: 'config/unicorn.rb',
        fixture: 'contents_with_violations.json'
      )

      subject.run

      messages = subject.violations.map(&:messages).flatten

      expect(messages).to eq([
        "Omit the parentheses in defs when the method doesn't accept any "\
        'arguments.',
        'Trailing whitespace detected.'
      ])
    end
  end

  describe '#accuse' do
    it 'add comments to the pull request regarding all current violations' do
      stub_pull_request_files_request('volmer/cerberus', 2)
      stub_contents_request(
        repo: 'volmer/cerberus',
        sha: '498b81cd038f8a3ac02f035a8537b7ddcff38a81',
        file: 'config/unicorn.rb'
      )
      stub_pull_request_comments_request('volmer/cerberus', 2)
      comment_request_1 = stub_comment_request(
        'violation1',
        repo: 'volmer/cerberus',
        pull_request: 2,
        file: 'config/unicorn.rb',
        commit: '498b81cd038f8a3ac02f035a8537b7ddcff38a81',
        line: 3
      )
      comment_request_2 = stub_comment_request(
        'violation2',
        repo: 'volmer/cerberus',
        pull_request: 2,
        file: 'config/unicorn.rb',
        commit: '498b81cd038f8a3ac02f035a8537b7ddcff38a81',
        line: 5
      )

      file = subject.pull_request.files.first

      subject.violations = [
        Policial::Violation.new(file, 3, 'violation1'),
        Policial::Violation.new(file, 5, 'violation2')
      ]

      subject.accuse

      expect(comment_request_1).to have_been_requested
      expect(comment_request_2).to have_been_requested
    end
  end
end
