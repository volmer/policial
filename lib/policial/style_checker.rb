# frozen_string_literal: true

module Policial
  # Public: Filters files to reviewable subset, builds linter based on file
  # extension and delegates to linter for line violations.
  class StyleChecker
    def initialize(pull_request, linters:)
      @pull_request = pull_request
      @linters = linters
    end

    def investigate
      violations = violations_in_checked_files.select(&:on_changed_line?)

      InvestigationResult.new(
        pull_request: @pull_request,
        linters: @linters,
        violations: violations
      )
    end

    private

    def violations_in_checked_files
      files_to_check.flat_map do |file|
        @linters.flat_map do |linter|
          linter.violations(file, @pull_request.head_commit)
        end
      end
    end

    def files_to_check
      @pull_request.files.reject(&:removed?)
    end
  end
end
