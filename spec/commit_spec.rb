# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

describe Policial::Commit do
  subject do
    described_class.new('volmer/cerberus', 'commitsha', 'my-branch', Octokit)
  end

  describe '#file_content' do
    let(:content) { '' }

    before do
      stub_contents_request_with_content(
        'volmer/cerberus',
        sha: 'commitsha',
        file: 'test.rb',
        content: content
      )
    end

    context 'when content is returned from GitHub' do
      let(:content) { 'some content' }

      it 'returns content' do
        expect(subject.file_content('test.rb')).to eq('some content')
      end
    end

    context 'when file contains special characters' do
      let(:content) { '€25.00' }

      it 'does not error when linters try writing to disk' do
        tmp_file = Tempfile.new('foo', encoding: 'utf-8')

        expect { tmp_file.write(subject.file_content('test.rb')) }
          .not_to raise_error
      end
    end

    context 'when nothing is returned from GitHub' do
      it 'returns blank string' do
        expect(subject.file_content('test.rb')).to eq('')
      end
    end

    context 'when content is nil' do
      it 'returns blank string' do
        expect(Octokit).to receive(:contents).and_return(nil)

        expect(subject.file_content('test.rb')).to eq('')
      end
    end

    context 'when error occurs when fetching from GitHub' do
      it 'returns blank string' do
        expect(Octokit).to receive(:contents).and_raise(Octokit::NotFound)

        expect(subject.file_content('test.rb')).to eq('')
      end
    end

    context 'when file too large error is raised' do
      it 'returns blank string' do
        error = Octokit::Forbidden.new(body: { errors: [code: 'too_large'] })

        expect(Octokit).to receive(:contents).and_raise(error)

        expect(subject.file_content('test.rb')).to eq('')
      end
    end
  end
end
