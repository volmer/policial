# frozen_string_literal: true

module Policial
  # Public: Starting with an Octokit client and a pull request,
  # it checks all changes introduced looking for style guide violations.
  class Detective
    attr_accessor :violations, :corrections
    attr_reader :github_client, :pull_request

    def initialize(github_client = nil)
      @github_client = github_client || Octokit
    end

    def brief(event_or_attributes)
      pull_request_attributes = extract_attributes(event_or_attributes)
      return unless pull_request_attributes
      @pull_request = PullRequest.new(
        pull_request_attributes.merge(github_client: @github_client)
      )
    end

    def investigate(options = {})
      return unless pull_request
      @violations ||= StyleChecker.new(pull_request, options).violations
    end

    def correct(options = {})
      return unless pull_request
      @corrections ||= StyleCorrector.new(pull_request, options).corrections
    end

    private

    def extract_attributes(event_or_attributes)
      if event_or_attributes.is_a?(PullRequestEvent)
        event_or_attributes.pull_request_attributes
      else
        event_or_attributes
      end
    end
  end
end
