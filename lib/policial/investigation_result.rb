# frozen_string_literal: true

module Policial
  # Public: a collection of information about an investigation,
  # including any violations found.
  class InvestigationResult
    attr_reader :pull_request, :linters, :violations, :corrected_files

    def initialize(pull_request:, linters:, violations:, corrected_files:)
      @pull_request = pull_request
      @linters = linters
      @violations = violations
      @corrected_files = corrected_files
    end
  end
end
