require 'scss_lint'

module Policial
  module StyleGuides
    # Public: Determine SCSS style guide violations per-line.
    class Scss < Base
      def config_file(*)
        SCSSLint::Config::FILE_NAME
      end

      def violations_in_file(file)
        absolute_path = File.expand_path(file.filename)
        return [] if config.excluded_file?(absolute_path)

        tempfile_from(file.filename, file.content) do |tempfile|
          runner.run([{ file: tempfile, path: absolute_path }])
        end

        violations(file)
      end

      private

      def config
        @config ||= tempfile_from(config_file, @repo_config.raw(self)) do |temp|
          SCSSLint::Config.load(temp, merge_with_default: true)
        end
      end

      def violations(file)
        runner.lints.map do |lint|
          Violation.new(file, lint.location.line, lint.description, lint)
        end
      end

      def runner
        @runner ||= SCSSLint::Runner.new(config)
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
