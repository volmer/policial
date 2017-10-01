# frozen_string_literal: true

require 'logger'

module Policial
  # Public: Checks number of files received from GitHub and notifies if user
  # reached GitHub per_page limit.
  class LimitsChecker
    DEFAULT_PERPAGE = 30

    def initialize(github_client:, files:)
      @github_client = github_client
      @files = files
    end

    def check
      return if @github_client.auto_paginate
      return if (@github_client.per_page || DEFAULT_PERPAGE) > @files.count
      raise IncompleteResultsError, "You reached GitHub per_page limit. \
Configure your octokit client to support auto pagination."
    end
  end
end
