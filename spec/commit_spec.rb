require 'spec_helper'

describe Policial::Commit do
  subject { described_class.new('volmer/cerberus', 'commitsha') }

  describe '#file_content' do
    let(:body) { nil }

    before do
      stub_contents_request(
        'volmer/cerberus',
        sha: 'commitsha',
        file: 'test.rb',
        body: body
      )
    end

    context 'when content is returned from GitHub' do
      let(:body) { { content: Base64.encode64('some content') }.to_json }

      it 'returns content' do
        expect(subject.file_content('test.rb')).to eq('some content')
      end
    end

    context 'when file contains special characters' do
      let(:body) { { content: Base64.encode64('€25.00') }.to_json }

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
      let(:body) { { content: nil }.to_json }

      it 'returns blank string' do
        expect(subject.file_content('test.rb')).to eq('')
      end
    end

    context 'when error occurs when fetching from GitHub' do
      it 'returns blank string' do
        expect(Octokit).to receive(:contents).and_raise(Octokit::NotFound)

        expect(subject.file_content('test.rb')).to eq('')
      end
    end
  end
end
