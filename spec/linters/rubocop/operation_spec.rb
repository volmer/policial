# frozen_string_literal: true

require 'spec_helper'
require 'policial/linters/rubocop'

describe Policial::Linters::RuboCop::Operation do
  let(:file) { double('file', filename: 'app/test.rb', content: 'puts "foo"') }
  let(:config) { ::RuboCop::ConfigLoader.default_configuration }
  subject { described_class.new(file, config) }

  describe '#build_team' do
    it 'returns a RuboCop::Cop::Team with auto_correct set to false' do
      expect(subject.build_team).not_to be_autocorrect
    end

    context 'when auto_correct: true is passed' do
      it 'returns a RuboCop::Cop::Team with auto_correct set to true' do
        expect(subject.build_team(auto_correct: true)).to be_autocorrect
      end
    end

    it 'excludes Rails cops' do
      cop_classes = subject.build_team.cops.map(&:class)
      expect(cop_classes).not_to include(::RuboCop::Cop::Rails::Blank)
    end

    context '#when config enables Rails cops' do
      let(:config) do
        ::RuboCop::ConfigLoader.merge_with_default(
          ::RuboCop::Config.new('Rails' => { 'Enabled' => true }), ''
        )
      end

      it 'includes Rails cops' do
        cop_classes = subject.build_team.cops.map(&:class)
        expect(cop_classes).to include(::RuboCop::Cop::Rails::Blank)
      end
    end
  end

  describe '#parsed_source' do
    it 'returns a source instance based on the given filename and content' do
      source = subject.parsed_source(file.filename, file.content)

      expected_path = config.base_dir_for_path_parameters + '/app/test.rb'

      expect(source.path).to eq(expected_path)
      expect(source.raw_source).to eq('puts "foo"')
    end
  end
end
