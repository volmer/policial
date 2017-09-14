# frozen_string_literal: true

require 'spec_helper'

describe Policial::LimitsChecker do
  let(:logger) { double(:logger) }
  let(:github_client) { Octokit }

  subject do
    described_class.new(
      files: files,
      github_client: github_client,
      logger: logger
    )
  end

  before do
    allow(Octokit).to receive(:auto_paginate).and_return(nil)
  end

  context 'when there are many files and there is no any limits' do
    let(:files) { [:file] * 30 }

    it 'notifies user about limit' do
      expect(logger).to receive(:call).exactly(3).times
      subject.call
    end
  end

  context 'when there are many files and files count equals to per_page' do
    let(:files) { [:file] * 20 }

    before { allow(Octokit).to receive(:per_page).and_return(20) }

    it 'notifies user about limit' do
      expect(logger).to receive(:call).exactly(3).times
      subject.call
    end
  end

  context 'on non-limit files count' do
    let(:files) { [:file] * 5 }

    it 'returns files on pull request' do
      expect(logger).not_to receive(:call)
      subject.call
    end
  end

  context "when github provider isn't octokit" do
    let(:github_client) { Octokit.dup }
    let(:files) { [:file] * 31 }

    it "doesn't notifies user about limit" do
      expect(logger).not_to receive(:call)
      subject.call
    end
  end

  context 'when there are many files but auto paginate enabled' do
    let(:files) { [:file] * 31 }

    before { allow(Octokit).to receive(:auto_paginate).and_return(true) }

    it "doesn't notifies user about limit" do
      expect(logger).not_to receive(:call)
      subject.call
    end
  end
end
