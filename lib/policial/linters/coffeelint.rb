# frozen_string_literal: true

require 'coffeelint'

module Policial
  module Linters
    # Public: Determine CoffeeLint style guide violations per-line.
    class CoffeeLint
      def initialize(config_file: 'coffeelint.json')
        @config_file = config_file
      end

      def violations(file, commit)
        return [] unless include_file?(file.filename)

        errors = ::Coffeelint.lint(file.content, config(commit))
        errors_to_violations(errors, file)
      end

      def correct(file, commit); end

      private

      def include_file?(filename)
        File.extname(filename) == '.coffee'
      end

      def config(commit)
        return @config if @config

        @config = JSON.parse(commit.file_content(@config_file)) || {}
      rescue JSON::ParserError
        {}
      end

      def errors_to_violations(errors, file)
        errors.map do |error|
          Violation.new(
            file,
            Range.new(error['lineNumber'], error['lineNumber']),
            error['message'],
            error['rule']
          )
        end
      end
    end
  end
end
