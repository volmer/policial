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
      klass = style_guide_class(filename)
      style_guides[klass] ||= klass.new(config)
    end

    def style_guide_class(filename)
      if (@options[:ruby] != false) && (filename =~ /.+\.rb\z/)
        StyleGuides::Ruby
      elsif (@options[:scss] == true) && (filename =~ /.+\.scss\z/)
        StyleGuides::Scss
      else
        StyleGuides::Unsupported
      end
    end

    def config
      @config ||= RepoConfig.new(pull_request.head_commit, @options)
    end
  end
end
