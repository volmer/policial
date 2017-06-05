# frozen_string_literal: true

require 'spec_helper'

describe Policial do
  describe '.linters' do
    before(:all) { @linters_initial_value = Policial.linters.dup }
    after { Policial.linters = @linters_initial_value.dup }

    it 'defaults to DEFAULT_LINTERS' do
      expect(Policial.linters).to eq(Policial::DEFAULT_LINTERS)
    end

    it 'can be overwritten' do
      custom = [Policial::Linters::Scss, Policial::Linters::Ruby]
      Policial.linters = custom

      expect(Policial.linters).to eq(custom)
    end

    it 'can be appended' do
      Policial.linters << Policial::Linters::Scss
      expect(Policial.linters).to include(Policial::Linters::Scss)
    end
  end
end
