# frozen_string_literal: true

require 'eslintrb'

module Policial
  module Linters
    # Public: Determine Javascript style guide violations per-line.
    class JavaScript
      def initialize(config_file: '.eslintrc.json')
        @config_file = config_file
      end

      def violations(file, config_loader)
        return [] unless include_file?(file.filename)

        errors = Eslintrb.lint(file.content, config(config_loader))
        errors_to_violations(errors, file)
      rescue ExecJS::Error => error
        raise LinterError,
              "ESLint has crashed because of #{error.class}: #{error.message}"
      end

      private

      def include_file?(filename)
        File.extname(filename) == '.js'
      end

      def config(config_loader)
        @config ||= begin
          content = config_loader.json(@config_file)
          content.empty? ? :defaults : content
        end
      end

      def errors_to_violations(errors, file)
        errors.map do |error|
          raise LinterError, error['message'] if error['line'].to_i.zero?

          Violation.new(
            file,
            Range.new(error['line'], error['line']),
            error['message'],
            error['ruleId'] || 'undefined'
          )
        end
      end
    end
  end
end
