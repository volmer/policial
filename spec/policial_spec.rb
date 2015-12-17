require 'spec_helper'

describe Policial do
  describe 'STYLE_GUIDES' do
    it 'includes Ruby' do
      expect(Policial::STYLE_GUIDES).to include(Policial::StyleGuides::Ruby)
    end

    it 'includes SCSS' do
      expect(Policial::STYLE_GUIDES).to include(Policial::StyleGuides::Scss)
    end
  end
end
