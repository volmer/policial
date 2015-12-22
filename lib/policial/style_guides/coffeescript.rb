require 'coffeelint'

module Policial
  module StyleGuides
    # Public: Determine Coffeescript style guide violations per-line.
    class Coffeescript < Base
      KEY = :coffeescript

      def config_file(*)
        'coffeelint.json'
      end

      def violations_in_file(file)
        return [] if ignore?(file.filename)

        errors = Coffeelint.lint(file.content, config)
        violations(file, errors)
      end

      private

      def config
        @config ||= begin
          JSON.parse(@repo_config.raw(self, '{}'))
        rescue JSON::ParserError
          {}
        end
      end

      def ignore?(filename)
        (filename =~ /.+\.coffee\z/).nil?
      end

      def violations(file, errors)
        errors.map do |error|
          Violation.new(
            file, error['lineNumber'], error['message'], error['rule'])
        end
      end
    end
  end
end
