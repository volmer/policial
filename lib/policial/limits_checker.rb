# frozen_string_literal: true

require 'logger'

module Policial
  # Public: Checks number of files received from GitHub and notifies if user
  # reached GitHub per_page limit.
  class LimitsChecker
    DEFAULT_PERPAGE = 30

    def initialize(github_client:, files:, logger: ->(text) { puts text })
      @github_client = github_client
      @files = files
      @logger = logger
    end

    def call
      return unless @github_client.eql?(Octokit) ||
                    @github_client.is_a?(Octokit::Client)
      return if @github_client.auto_paginate
      return if (@github_client.per_page || DEFAULT_PERPAGE) > @files.count
      @logger.call('**************************************************')
      @logger.call("WARNING: You reached GitHub per_page limit. \
Configure your octokit client to support auto pagination.")
      @logger.call('**************************************************')
    end
  end
end
