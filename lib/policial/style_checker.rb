# frozen_string_literal: true

module Policial
  # Public: Filters files to reviewable subset, builds linter based on file
  # extension and delegates to linter for line violations.
  class StyleChecker
    def initialize(pull_request, linters:)
      @pull_request = pull_request
      @linters = linters
    end

    def violations
      @violations ||= violations_in_checked_files.select(&:on_changed_line?)
    end

    private

    def violations_in_checked_files
      files_to_check.flat_map do |file|
        @linters.flat_map { |linter| linter.violations(file, config_loader) }
      end
    end

    def files_to_check
      @pull_request.files.reject(&:removed?)
    end

    def config_loader
      @config_loader ||= ConfigLoader.new(@pull_request.head_commit)
    end
  end
end
