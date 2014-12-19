module Policial
  # Public: Starting with unparsed data coming from a pull request event,
  # it checks all changes introduced looking for style guide violations. It
  # also accuse all present violations through comments on all relevant lines
  # in the pull request.
  class Investigation
    attr_accessor :violations, :pull_request

    def initialize(unparsed_data)
      @payload      = Payload.new(unparsed_data)
      @pull_request = PullRequest.new(@payload)
    end

    def run
      return unless relevant_pull_request?
      @violations ||= StyleChecker.new(@pull_request).violations
    end

    def accuse
      return if @violations.blank?

      @violations.each do |violation|
        if commenting_policy.allowed_for?(violation)
          pull_request.comment_on_violation(violation)
        end
      end
    end

    private

    def commenting_policy
      @commenting_policy ||= CommentingPolicy.new(pull_request)
    end

    def relevant_pull_request?
      pull_request.opened? || pull_request.synchronize?
    end
  end
end
