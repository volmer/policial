# frozen_string_literal: true

require 'eslintrb'

module Policial
  module StyleGuides
    # Public: Determine Javascript style guide violations per-line.
    class Javascript < Base
      KEY = :javascript

      def violations_in_file(file)
        return violations(file, []) unless file.filename =~ filename_pattern
        errors = Eslintrb.lint(file.content, config ||= :defaults)
        violations(file, errors)
      end

      def exclude_file?(_filename)
        false
      end

      def filename_pattern
        /.+\.js\z/
      end

      def default_config_file
        '.eslintrc.json'
      end

      private

      def config
        @config ||= @config_loader.json(config_file)
      end

      def violations(file, errors)
        errors.map do |error|
          Violation.new(
            file, error['line'], error['message'], error['ruleId'])
        end
      end
    end
  end
end
