# frozen_string_literal: true

require 'logger'

module Policial
  # Public: Insures that Octokit client pagination configured correctly.
  class LimitsChecker
    def initialize(github_client:)
      @github_client = github_client
    end

    def check
      return if @github_client.auto_paginate
      return if @github_client.last_response.rels.empty?
      raise IncompleteResultsError, "You reached GitHub per_page limit. \
Configure your Octokit client to support auto pagination."
    end
  end
end
