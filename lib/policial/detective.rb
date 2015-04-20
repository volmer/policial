module Policial
  # Public: Starting with an Octokit client and a pull request,
  # it checks all changes introduced looking for style guide violations. It
  # also accuses all present violations through comments on all relevant lines
  # in the pull request.
  class Detective
    attr_accessor :violations
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

    def investigate
      return unless pull_request
      @violations ||= StyleChecker.new(pull_request).violations
    end

    def accuse
      return if violations.nil?

      commenter = Commenter.new(pull_request)

      violations.each do |violation|
        if accusation_policy.allowed_for?(violation)
          commenter.comment_violation(violation)
        end
      end
    end

    private

    def accusation_policy
      @accusation_policy ||= AccusationPolicy.new(pull_request)
    end

    def extract_attributes(event_or_attributes)
      if event_or_attributes.is_a?(PullRequestEvent)
        event_or_attributes.pull_request_attributes
      else
        event_or_attributes
      end
    end
  end
end
