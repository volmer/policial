# frozen_string_literal: true

require 'spec_helper'
require 'policial/linters/rubocop'

describe Policial::Linters::RuboCop::Corrector do
  let(:file) { build_file('app/test.rb', 'puts(:foo,)') }
  let(:config) { ::RuboCop::ConfigLoader.default_configuration }
  subject { described_class.new(file, config) }

  describe '#correct' do
    it 'returns the file content with violations corrected' do
      expect(subject.correct).to eq(
        "# frozen_string_literal: true\n\nputs(:foo)\n"
      )
    end

    context 'when line with violations was not changed by commit' do
      let(:file) do
        build_file(
          'app/test.rb',
          "# frozen_string_literal: true\n\nputs(:foo,)\nputs(:bar )\n"
        )
      end

      it 'corrects only changed lines' do
        expect(file)
          .to receive(:line_at)
          .with(3).and_return(double(changed?: false)).twice
        expect(file)
          .to receive(:line_at)
          .with(4).and_return(double(changed?: true)).once

        expect(subject.correct).to eq(
          "# frozen_string_literal: true\n\nputs(:foo,)\nputs(:bar)\n"
        )
      end
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

    def build_file(name, *lines)
      file = double('file', filename: name, content: lines.join("\n"))
      allow(file).to receive(:line_at) do |n|
        Policial::Line.new(n, lines[n - 1], n - 1)
      end
      file
    end
  end
end
