require 'spec_helper'

describe Policial::RepoConfig do
  subject { described_class.new(commit) }
  let(:commit) { double('Commit') }

  describe '#enabled_for?' do
    it 'returns true for StyleGuides::Ruby' do
      expect(subject).to be_enabled_for(
        Policial::StyleGuides::Ruby.new(subject)
      )
    end
  end

  describe '#for' do
    context 'when Ruby config file is specified' do
      it 'returns parsed config' do
        config_for_file('.rubocop.yml', <<-EOS.strip_heredoc)
          StringLiterals:
            EnforcedStyle: double_quotes

          LineLength:
            Max: 90
        EOS

        result = subject.for(Policial::StyleGuides::Ruby.new(subject))

        expect(result).to eq(
          'StringLiterals' => { 'EnforcedStyle' => 'double_quotes' },
          'LineLength' => { 'Max' => 90 }
        )
      end
    end

    def config_for_file(file_path, content)
      allow(commit).to receive(:file_content).with(file_path)
        .and_return(content)
    end
  end
end
