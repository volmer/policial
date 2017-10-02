# frozen_string_literal: true

require 'spec_helper'

describe Policial::LimitsChecker do
  subject { described_class.new(github_client: octokit) }
  let(:octokit) { class_double(Octokit) }

  context 'when Octokit auto paginate is enabled' do
    before { allow(octokit).to receive(:auto_paginate).and_return(true) }

    it "doesn't notifies user about limit" do
      expect { subject.check }.to_not raise_error
    end
  end

  context 'when Octokit auto paginate is disabled' do
    before do
      allow(octokit).to receive(:auto_paginate).and_return(false)
      allow(octokit).to receive(:last_response).and_return(last_response)
    end

    context 'and there are no any refs' do
      let(:last_response) { instance_double(Sawyer::Response, rels: []) }

      it "doesn't notifies user about limit" do
        expect { subject.check }.to_not raise_error
      end
    end

    context 'and there are some refs' do
      let(:last_response) { instance_double(Sawyer::Response, rels: [:ref]) }

      it 'raises error about files limit' do
        expect { subject.check }.to raise_error(
          Policial::IncompleteResultsError
        )
      end
    end
  end
end
