# frozen_string_literal: true

module Policial
  # Public: Filters files to reviewable subset, builds style guide based on file
  # extension and delegates to style guide for line violations.
  class StyleChecker
    def initialize(pull_request, options = {})
      @pull_request = pull_request
      @style_guides = {}
      @options = options
    end

    def violations
      @violations ||= violations_in_checked_files.select(&:on_changed_line?)
    end

    private

    def violations_in_checked_files
      files_to_check.flat_map do |file|
        style_guides.flat_map do |style_guide|
          if style_guide.investigate?(file.filename)
            style_guide.violations_in_file(file)
          else
            []
          end
        end
      end
    end

    def files_to_check
      @pull_request.files.reject(&:removed?)
    end

    def style_guides
      Policial.style_guides.map do |klass|
        @style_guides[klass] ||= klass.new(
          config_loader, @options[klass::KEY] || {})
      end
    end

    def config_loader
      @config_loader ||= ConfigLoader.new(@pull_request.head_commit)
    end
  end
end
