# frozen_string_literal: true

require 'erb_lint'

module Policial
  module StyleGuides
    # Public: Determine ERB style guide violations per-line.
    class Erb < Base
      KEY = :erb

      def violations_in_file(file)
        errors = ERBLint.lint(file.content, config)
        violations(file, errors)
      end

      def exclude_file?(_filename)
        false
      end

      def filename_pattern
        /.+\.html\.erb\z/
      end

      def default_config_file
        '.erb-lint.yml'
      end

      private

      def config
        @config ||= begin
          content = @config_loader.yaml(config_file)
          content.empty? ? :defaults : content
        end
      end

      def violations(file, errors)
        errors.map do |error|
          Violation.new(
            file, error[:line], error[:message], error[:ruleId])
        end
      end
    end
  end
end
