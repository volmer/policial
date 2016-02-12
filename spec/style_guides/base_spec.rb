# frozen_string_literal: true

require 'spec_helper'

describe Policial::StyleGuides::Base do
  subject { described_class.new(config_loader) }
  let(:config_loader) { Policial::ConfigLoader.new('commit') }

  describe '#violations_in_file' do
    it 'raises NotImplementedError' do
      expect { subject.violations_in_file('file') }
        .to raise_error(
          NotImplementedError, 'must implement #violations_in_file'
        )
    end
  end

  describe '#filename_pattern' do
    it 'raises NotImplementedError' do
      expect { subject.filename_pattern }
        .to raise_error(
          NotImplementedError, 'must implement #filename_pattern'
        )
    end
  end

  describe '#default_config_file' do
    it 'raises NotImplementedError' do
      expect { subject.default_config_file }
        .to raise_error(
          NotImplementedError, 'must implement #default_config_file'
        )
    end
  end

  describe '#exclude_file?' do
    it 'raises NotImplementedError' do
      expect { subject.exclude_file?('filename') }
        .to raise_error(
          NotImplementedError, 'must implement #exclude_file?'
        )
    end
  end

  describe '#config_file' do
    before do
      allow(subject).to receive(:default_config_file).and_return('.default.yml')
    end

    context 'when no :config_file option is provided' do
      it 'is the default config file' do
        expect(subject.config_file).to eq('.default.yml')
      end
    end

    context 'when a :config_file option is provided' do
      subject { described_class.new(config_loader, config_file: 'config.yml') }

      it 'is the :config_file option' do
        expect(subject.config_file).to eq('config.yml')
      end
    end

    context 'when a nil :config_file option is provided' do
      subject { described_class.new(config_loader, config_file: nil) }

      it 'is the default config file' do
        expect(subject.config_file).to eq('.default.yml')
      end
    end

    context 'when a blank :config_file option is provided' do
      subject { described_class.new(config_loader, config_file: ' ') }

      it 'is the default config file' do
        expect(subject.config_file).to eq('.default.yml')
      end
    end
  end

  describe '#investigate?' do
    context 'when style guide is enabled and filename matches pattern' do
      before do
        allow(subject).to receive(:filename_pattern).and_return(/.*\.erb/)
      end

      context 'when filename is not excluded' do
        before do
          allow(subject).to receive(
            :exclude_file?).with('app/view.erb').and_return(false)
        end

        it 'is true' do
          expect(subject.investigate?('app/view.erb')).to be true
        end
      end

      context 'when filename is excluded' do
        before do
          allow(subject).to receive(
            :exclude_file?).with('app/view.erb').and_return(true)
        end

        it 'is false' do
          expect(subject.investigate?('app/view.erb')).to be false
        end
      end
    end

    context 'when style guide is enabled and filename is not excluded' do
      before do
        allow(subject).to receive(
          :exclude_file?).with('app/view.erb').and_return(false)
      end

      context 'when filename does not match pattern' do
        before do
          allow(subject).to receive(:filename_pattern).and_return(/.*\.js/)
        end

        it 'is false' do
          expect(subject.investigate?('app/view.erb')).to be false
        end
      end
    end

    context 'when filename matches pattern and it is not excluded' do
      before do
        allow(subject).to receive(:filename_pattern).and_return(/.*\.erb/)
        allow(subject).to receive(
          :exclude_file?).with('app/view.erb').and_return(false)
      end

      context 'when style guide is disabled' do
        subject { described_class.new(config_loader, enabled: false) }

        it 'is false' do
          expect(subject.investigate?('app/view.erb')).to be false
        end
      end
    end
  end
end
