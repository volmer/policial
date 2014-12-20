require 'spec_helper'

describe Policial::PullRequest do
  subject { described_class.new('volmer/cerberus', 4, 'commitsha') }

  describe '#repo' do
    it 'returns the repo name' do
      expect(subject.repo).to eq('volmer/cerberus')
    end
  end

  describe '#number' do
    it 'returns the pull request number' do
      expect(subject.number).to eq(4)
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
      expect_any_instance_of(Policial::GithubApi)
        .to receive(:pull_request_comments)
        .with('volmer/cerberus', 4).and_return(:tons_of_comments)

      expect(subject.comments).to eq(:tons_of_comments)
    end
  end

  describe '#files' do
    let(:files) do
      [
        double('file_1', filename: 'lib/code_1.rb'),
        double('file_2', filename: 'lib/code_2.rb')
      ]
    end

    before do
      expect_any_instance_of(Policial::GithubApi)
        .to receive(:pull_request_files)
        .with('volmer/cerberus', 4).and_return(files)
    end

    it 'returns files on pull request' do
      expect(subject.files.count).to eq(2)
    end

    describe 'the returned files' do
      it 'has the proper filenames' do
        expect(subject.files.first.filename).to eq('lib/code_1.rb')
        expect(subject.files.last.filename).to eq('lib/code_2.rb')
      end

      it 'belongs to the pull request head commit' do
        expect(subject.files.first.commit).to eq(subject.head_commit)
        expect(subject.files.last.commit).to eq(subject.head_commit)
      end
    end
  end
end
