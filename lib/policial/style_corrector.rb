# frozen_string_literal: true

module Policial
  # Public: Filters files to reviewable subset, builds linter based on file
  # extension and delegates to linter for corrections.
  class StyleCorrector < StyleOperation
    def corrected_files
      @corrected_files ||= corrections_in_checked_files.compact
    end

    private

    def corrections_in_checked_files
      files_to_check.flat_map do |file|
        linters.flat_map do |linter|
          if linter.investigate?(file.filename) && linter.class.supports_autocorrect?
            linter.autocorrect(file)
          else
            []
          end
        end
      end
    end
  end
end
