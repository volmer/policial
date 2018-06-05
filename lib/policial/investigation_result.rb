# frozen_string_literal: true

module Policial
  # Public: a collection of information about an investigation,
  # including any violations found.
  class InvestigationResult
    attr_reader :pull_request, :linters, :violations

    def initialize(pull_request:, linters:, violations:)
      @pull_request = pull_request
      @linters = linters
      @violations = violations
    end
  end
end
