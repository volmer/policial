module Policial
  # Public: Filters files to reviewable subset, builds style guide based on file
  # extension and delegates to style guide for line violations.
  class StyleChecker
    def initialize(pull_request)
      @pull_request = pull_request
      @style_guides = {}
    end

    def violations
      @violations ||= violations_in_checked_files.select(&:on_changed_line?)
    end

    private

    attr_reader :pull_request, :style_guides

    def violations_in_checked_files
      files_to_check.flat_map do |file|
        style_guide(file.filename).violations_in_file(file)
      end
    end

    def files_to_check
      pull_request.files.reject(&:removed?).select do |file|
        style_guide(file.filename).enabled?
      end
    end

    def style_guide(filename)
      style_guide_class = style_guide_class(filename)
      style_guides[style_guide_class] ||= style_guide_class.new(config)
    end

    def style_guide_class(filename)
      case filename
      when /.+\.rb\z/
        StyleGuides::Ruby
      else
        StyleGuides::Unsupported
      end
    end

    def config
      @config ||= RepoConfig.new(pull_request.head_commit)
    end
  end
end
