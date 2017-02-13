# frozen_string_literal: true

module Policial
  module StyleGuides
    # Public: Determine SCSS style guide violations per-line.
    class Scss < Base
      KEY = :scss

      def violations_in_file(file)
        absolute_path = File.expand_path(file.filename)

        runner = new_runner

        tempfile_from(file.filename, file.content) do |tempfile|
          runner.run([{ file: tempfile, path: absolute_path }])
        end

        violations(runner, file)
      end

      def include_file?(filename)
        File.extname(filename) == '.scss'
      end

      def exclude_file?(filename)
        config.excluded_file?(File.expand_path(filename))
      end

      def default_config_file
        require 'scss_lint'
        SCSSLint::Config::FILE_NAME
      end

      private

      def config
        require 'scss_lint'
        @config ||= begin
          content = @config_loader.raw(config_file)
          tempfile_from(config_file, content) do |temp|
            SCSSLint::Config.load(temp, merge_with_default: true)
          end
        end
      end

      def violations(runner, file)
        runner.lints.map do |lint|
          linter_name = lint.linter&.name || 'undefined'
          Violation.new(
            file, lint.location.line, lint.description, linter_name
          )
        end
      end

      def new_runner
        require 'scss_lint'
        SCSSLint::Runner.new(config)
      end

      def tempfile_from(filename, content)
        Tempfile.create(File.basename(filename), Dir.pwd) do |tempfile|
          tempfile.write(content)
          tempfile.rewind

          yield(tempfile)
        end
      end
    end
  end
end
