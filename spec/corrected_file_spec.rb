# frozen_string_literal: true

require 'spec_helper'

describe Policial::CorrectedFile do
  let(:corrected_file) { described_class.new(commit_file, 'Some new content.') }
  subject { corrected_file }

  describe '#content' do
    it { expect(subject.content).to eq 'Some new content.' }
  end

  describe '#uncorrected_content' do
    it { expect(subject.uncorrected_content).to eq 'some content' }
  end

  describe '#filename' do
    it { expect(subject.filename).to eq 'test.rb' }
  end

  describe '#sha' do
    it { expect(subject.sha).to eq 'abc289171' }
  end

  def commit_file(options = {})
    file = double(:file, { patch: '', sha: 'abc289171', filename: 'test.rb', status: 'modified' })
    commit = double(
      :commit,
      repo_name: 'test/test',
      sha: 'abc',
      file_content: 'some content'
    )
    Policial::CommitFile.new(file, commit)
  end
end
