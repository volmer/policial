require 'spec_helper'

describe Policial::RepoConfig do
  subject { described_class.new(commit) }
  let(:commit) { double('Commit') }

  describe '#enabled_for?' do
    context 'when all style guides are disabled' do
      before do
        allow(Policial).to receive(:enabled_style_guides).and_return([])
      end

      it 'returns false for all style guides' do
        Policial::STYLE_GUIDES.each do |style_guide_class|
          expect(subject).not_to be_enabled_for(style_guide_class.new(subject))
        end
      end
    end

    context 'when Ruby is enabled' do
      before do
        allow(Policial).to receive(
          :enabled_style_guides
        ).and_return(
          [Policial::StyleGuides::Ruby]
        )
      end

      it 'returns true for StyleGuides::Ruby' do
        expect(subject).to be_enabled_for(
          Policial::StyleGuides::Ruby.new(subject)
        )
      end
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
