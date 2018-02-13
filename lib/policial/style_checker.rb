# frozen_string_literal: true

module Policial
  # Public: Filters files to reviewable subset, builds linter based on file
  # extension and delegates to linter for line violations.
  class StyleChecker
    def initialize(pull_request, options = {})
      @pull_request = pull_request
      @linters = {}
      @options = options
    end

    def violations
      @violations ||= violations_in_checked_files.select(&:on_changed_line?)
    end

    def corrections
      @corrections ||= corrections_in_checked_files.compact
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

    def files_to_check
      @pull_request.files.reject(&:removed?)
    end

    def linters
      Policial.linters.map do |klass|
        @linters[klass] ||= klass.new(
          config_loader, @options[klass::KEY] || {}
        )
      end
    end

    def config_loader
      @config_loader ||= ConfigLoader.new(@pull_request.head_commit)
    end
  end
end
