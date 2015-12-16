require 'coffeelint'

module Policial
  module StyleGuides
    # Public: Determine Coffeescript style guide violations per-line.
    class Coffeescript < Base
      def coffeelint_config_file(*)
        'coffeelint.json'
      end

      def violations_in_file(file)
        tempfile_from(file.filename, file.content) do |tempfile|
          errors = Coffeelint.lint_file(tempfile, config_file: config)
          violations(file, errors)
        end
      end

      private

      def config
        @config ||= coffeelint_config_file
      end

      def violations(file, errors)
        errors.map do |error|
          Violation.new(file, error['lineNumber'], error['message'], error)
        end
      end

      def tempfile_from(filename, content)
        filename = File.basename(filename)
        Tempfile.create(File.basename(filename), Dir.pwd) do |tempfile|
          tempfile.write(content)
          tempfile.rewind

          yield(tempfile)
        end
      end
    end
  end
end
