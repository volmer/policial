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
      InvestigationResult.new(
        pull_request: @pull_request,
        linters: @linters,
        violations: violations.select(&:on_changed_line?),
        corrected_files: corrected_files.compact
      )
    end

    private

    def violations
      files_to_check.flat_map do |file|
        @linters.flat_map do |linter|
          linter.violations(file, @pull_request.head_commit)
        end
      end
    end

    def corrected_files
      files_to_check.flat_map do |file|
        @linters.flat_map do |linter|
          new_content = linter.correct(file, @pull_request.head_commit)
          build_corrected_file(file, new_content)
        end
      end
    end

    def files_to_check
      @pull_request.files.reject(&:removed?)
    end

    def build_corrected_file(file, new_content)
      return unless new_content

      CorrectedFile.new(file, new_content)
    end
  end
end
