require 'spec_helper'

describe Policial do
  after { Policial.style_guides = Policial::DEFAULT_STYLE_GUIDES }

  describe '.style_guides' do
    it 'defaults to DEFAULT_STYLE_GUIDES' do
      expect(Policial.style_guides).to eq(Policial::DEFAULT_STYLE_GUIDES)
    end

    it 'can be overwritten' do
      custom = [Policial::StyleGuides::Scss, Policial::StyleGuides::Ruby]
      Policial.style_guides = custom

      expect(Policial.style_guides).to eq(custom)
    end
  end
end
