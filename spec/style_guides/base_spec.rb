require 'spec_helper'

describe Policial::StyleGuides::Base do
  subject { described_class.new(repo_config) }
  let(:repo_config) { Policial::RepoConfig.new('commit') }

  describe '#enabled?' do
    it 'asks the repo config if it is enabled or not' do
      expect(subject.enabled?).to be false
    end
  end

  describe '#violations_in_file' do
    it 'raises NotImplementedError' do
      expect { subject.violations_in_file('file') }
        .to raise_error(
          NotImplementedError, 'must implement #violations_in_file'
        )
    end
  end
end
