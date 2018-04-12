# frozen_string_literal: true

require 'eslintrb'

module Policial
  module Linters
    # Public: Determine Javascript style guide violations per-line.
    class ESLint
      def initialize(config_file: '.eslintrc.json')
        @config_file = config_file
      end

      def violations(file, commit)
        return [] unless include_file?(file.filename)

        errors = Eslintrb.lint(file.content, config(commit))
        errors_to_violations(errors, file)
      rescue ExecJS::Error => error
        raise LinterError,
              "ESLint has crashed because of #{error.class}: #{error.message}"
      end

      private

      def include_file?(filename)
        File.extname(filename) == '.js'
      end

      def config(commit)
        @config ||= begin
          JSON.parse(commit.file_content(@config_file)) || {}
        rescue JSON::ParserError
          {}
        end

        @config.empty? ? :defaults : @config
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
