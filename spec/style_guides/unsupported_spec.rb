require 'spec_helper'

describe Policial::StyleGuides::Unsupported do
  describe '#violations_in_file' do
    it 'returns an empty array' do
      style_guide = described_class.new({})

      expect(style_guide.violations_in_file('file.txt')).to eq []
    end
  end
end
