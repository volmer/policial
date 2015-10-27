require 'spec_helper'

describe Policial::Detective do
  let(:pull_request_event) do
    Policial::PullRequestEvent.new(
      JSON.parse(
        File.read('spec/support/fixtures/pull_request_opened_event.json')
      )
    )
  end

  describe '#brief' do
    it 'creates a pull request based on the given pull request event' do
      subject.brief(pull_request_event)

      expect(subject.pull_request.repo).to eq('volmer/cerberus')
      expect(subject.pull_request.number).to eq(2)
      expect(subject.pull_request.user).to eq('volmerius')
    end

    it 'creates a pull request based on the given pull request attributes' do
      subject.brief(
        repo: 'volmer/policial',
        number: 666,
        user: 'rafaelfranca',
        head_sha: '123abc'
      )

      expect(subject.pull_request.repo).to eq('volmer/policial')
      expect(subject.pull_request.number).to eq(666)
      expect(subject.pull_request.user).to eq('rafaelfranca')
    end

    context 'when the given event is invalid' do
      let(:pull_request_event) { Policial::PullRequestEvent.new({}) }

      it 'does not initialize a pull request' do
        subject.brief(pull_request_event)

        expect(subject.pull_request).to be_nil
      end
    end
  end

  describe '#investigate' do
    context 'when detective is briefed about a pull request' do
      before do
        stub_pull_request_files_request('volmer/cerberus', 2)
        stub_contents_request_with_fixture(
          'volmer/cerberus',
          sha: '498b81cd038f8a3ac02f035a8537b7ddcff38a81',
          file: '.rubocop.yml',
          fixture: 'config_contents.json'
        )

        subject.brief(pull_request_event)
      end

      it 'finds and returns all violations present in the pull request' do
        stub_contents_request_with_fixture(
          'volmer/cerberus',
          sha: '498b81cd038f8a3ac02f035a8537b7ddcff38a81',
          file: 'config/unicorn.rb',
          fixture: 'contents_with_violations.json'
        )

        expect(subject.investigate).to eq(subject.violations)

        messages = subject.violations.map(&:messages).flatten

        expect(messages).to eq([
          "Omit the parentheses in defs when the method doesn't accept any "\
          'arguments.',
          'Trailing whitespace detected.'
        ])
      end

      it 'returns empty if no violations are found' do
        stub_contents_request_with_fixture(
          'volmer/cerberus',
          sha: '498b81cd038f8a3ac02f035a8537b7ddcff38a81',
          file: 'config/unicorn.rb',
          fixture: 'contents.json'
        )

        expect(subject.investigate).to be_empty
      end

      it 'forwards any given options to StyleChecker' do
        stub_contents_request_with_fixture(
          'volmer/cerberus',
          sha: '498b81cd038f8a3ac02f035a8537b7ddcff38a81',
          file: 'config/unicorn.rb',
          fixture: 'contents_with_violations.json'
        )

        expect(Policial::StyleChecker).to receive(:new).with(
          anything, my: :option
        ).and_call_original

        subject.investigate(my: :option)
      end
    end

    context 'when detective is not briefed about a pull request' do
      it 'is nil' do
        expect(subject.investigate).to be_nil
      end
    end
  end

  describe '#accuse' do
    it 'add comments to the pull request regarding all current violations' do
      stub_pull_request_files_request('volmer/cerberus', 2)
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
      subject.brief(pull_request_event)
      file = subject.pull_request.files.first
      violation_1 = double('offense', line: 3,
                                      message: 'violation1',
                                      cop_name: 'cop')
      violation_2 = double('offense', line: 5,
                                      message: 'violation2',
                                      cop_name: 'cop')

      subject.violations = [
        Policial::Violation.new(file, violation_1),
        Policial::Violation.new(file, violation_2)
      ]

      subject.accuse

      expect(comment_request_1).to have_been_requested
      expect(comment_request_2).to have_been_requested
    end

    it 'does nothing if there are no violations' do
      subject.violations = nil

      expect(subject.accuse).to be_nil
    end
  end

  describe '#github_client' do
    context 'when a custom client is set' do
      let(:custom_client) { Octokit::Client.new }
      subject { described_class.new(custom_client) }

      it 'is the client' do
        expect(subject.github_client).to eq(custom_client)
      end
    end

    context 'when no client is set' do
      it 'is Octokit' do
        expect(subject.github_client).to eq(Octokit)
      end
    end
  end
end
