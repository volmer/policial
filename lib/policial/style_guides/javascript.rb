# frozen_string_literal: true

require 'eslintrb'

module Policial
  module StyleGuides
    # Public: Determine Javascript style guide violations per-line.
    class JavaScript < Base
      KEY = :javascript

      def violations_in_file(file)
        errors = Eslintrb.lint(file.content, config)
        violations(file, errors)
      end

      def exclude_file?(_filename)
        false
      end

      def filename_patterns
        [/.+\.js\z/]
      end

      def default_config_file
        '.eslintrc.json'
      end

      private

      def config
        @config ||= begin
          content = @config_loader.json(config_file)
          content.empty? ? :defaults : content
        end
      end

      def violations(file, errors)
        errors.map do |error|
          raise LinterError, error['message'] if error['line'].to_i.zero?

          Violation.new(
            file,
            error['line'],
            error['message'],
            error['ruleId'] || 'undefined'
          )
        end
      end
    end
  end
end
