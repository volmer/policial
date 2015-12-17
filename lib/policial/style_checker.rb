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
          style_guide.violations_in_file(file)
        end
      end
    end

    def files_to_check
      @pull_request.files.reject(&:removed?)
    end

    def style_guides
      style_guide_classes.map do |klass|
        @style_guides[klass] ||= klass.new(config)
      end
    end

    def style_guide_classes
      @classes ||= Policial::STYLE_GUIDES.reject do |klass|
        @options[klass::KEY] == false
      end
    end

    def config
      @config ||= RepoConfig.new(@pull_request.head_commit, @options)
    end
  end
end
