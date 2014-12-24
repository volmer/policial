module Policial
  # Public: Starting with unparsed data coming from a pull request event,
  # it checks all changes introduced looking for style guide violations. It
  # also accuse all present violations through comments on all relevant lines
  # in the pull request.
  class Investigation
    attr_accessor :violations, :pull_request

    def initialize(pull_request)
      @pull_request = pull_request
    end

    def run
      @violations ||= StyleChecker.new(@pull_request).violations
    end

    def accuse
      return if @violations.nil?

      commenter = Commenter.new(@pull_request)

      @violations.each do |violation|
        if accusation_policy.allowed_for?(violation)
          commenter.comment_violation(violation)
        end
      end
    end

    private

    def accusation_policy
      @accusation_policy ||= AccusationPolicy.new(@pull_request)
    end
  end
end
