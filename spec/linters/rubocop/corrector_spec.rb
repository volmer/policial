# frozen_string_literal: true

require 'spec_helper'
require 'policial/linters/rubocop'

describe Policial::Linters::RuboCop::Corrector do
  let(:file) { double('file', filename: 'app/test.rb', content: 'puts(:foo,)') }
  let(:config) { ::RuboCop::ConfigLoader.default_configuration }
  subject { described_class.new(file, config) }

  describe '#correct' do
    it 'returns the file content with violations corrected' do
      expect(subject.correct).to eq(
        "# frozen_string_literal: true\n\nputs(:foo)\n"
      )
    end

    context 'when file does not have violations' do
      let(:file) do
        double(
          'file',
          filename: 'app/test.rb',
          content: "# frozen_string_literal: true\n\nputs(:foo)\n"
        )
      end

      it 'returns nil' do
        expect(subject.correct).to be_nil
      end
    end

    context 'when RuboCop keeps on changing the source indefinitely' do
      before do
        allow_any_instance_of(::RuboCop::Cop::Team)
          .to receive(:updated_source_file?).and_return(true)
      end

      it 'raises an error' do
        expect { subject.correct }
          .to raise_error(Policial::InfiniteCorrectionLoop)
      end
    end

    context 'when RuboCop keeps returning the same source checksum' do
      before do
        allow_any_instance_of(::RuboCop::ProcessedSource)
          .to receive(:checksum).and_return('123')
      end

      it 'raises an error' do
        expect { subject.correct }
          .to raise_error(Policial::InfiniteCorrectionLoop)
      end
    end
  end
end
