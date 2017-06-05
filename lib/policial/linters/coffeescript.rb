# frozen_string_literal: true

require 'coffeelint'

module Policial
  module Linters
    # Public: Determine CoffeeScript style guide violations per-line.
    class CoffeeScript < Base
      KEY = :coffeescript

      def violations_in_file(file)
        errors = Coffeelint.lint(file.content, config)
        violations(file, errors)
      end

      def include_file?(filename)
        File.extname(filename) == '.coffee'
      end

      def default_config_file
        'coffeelint.json'
      end

      private

      def config
        @config ||= @config_loader.json(config_file)
      end

      def violations(file, errors)
        errors.map do |error|
          Violation.new(
            file, error['lineNumber'], error['message'], error['rule']
          )
        end
      end
    end
  end
end
