# frozen_string_literal: true

module Policial
  # Public: Filters files to reviewable subset, builds linter based on file
  # extension and delegates to linter for line violations.
  class StyleChecker < StyleOperation
    def violations
      @violations ||= violations_in_checked_files.select(&:on_changed_line?)
    end

    private

    def violations_in_checked_files
      files_to_check.flat_map do |file|
        linters.flat_map do |linter|
          if linter.investigate?(file.filename)
            linter.violations_in_file(file)
          else
            []
          end
        end
      end
    end
  end
end
