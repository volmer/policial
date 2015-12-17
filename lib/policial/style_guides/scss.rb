module Policial
  module StyleGuides
    # Public: Determine SCSS style guide violations per-line.
    class Scss < Base
      KEY = :scss

      def config_file(*)
        require 'scss_lint'
        SCSSLint::Config::FILE_NAME
      end

      def violations_in_file(file)
        require 'scss_lint'

        absolute_path = File.expand_path(file.filename)

        return [] if ignore?(absolute_path)

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

      def ignore?(filename)
        return true unless filename =~ /.+\.scss\z/
        config.excluded_file?(filename)
      end

      def violations(file)
        runner.lints.map do |lint|
          Violation.new(
            file, lint.location.line, lint.description, lint.linter.name)
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
