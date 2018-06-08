# frozen_string_literal: true

module Policial
  module Linters
    # Public: Determine SCSS style guide violations per-line.
    class SCSSLint
      def initialize(config_file: '.scss-lint.yml')
        @config_file = config_file
      end

      def violations(file, commit)
        require 'scss_lint'
        return [] unless include_file?(file.filename, commit)

        absolute_path = File.expand_path(file.filename)

        runner = new_runner(commit)

        tempfile_from(file.filename, file.content) do |tempfile|
          runner.run([{ file: tempfile, path: absolute_path }])
        end

        lints_to_violations(runner, file)
      rescue ::SCSSLint::Exceptions::LinterError => error
        raise LinterError, error.message
      end

      def correct(file, commit); end

      private

      def include_file?(filename, commit)
        File.extname(filename) == '.scss' &&
          !config(commit).excluded_file?(File.expand_path(filename))
      end

      def config(commit)
        require 'scss_lint'
        @config ||= begin
          content = commit.file_content(@config_file)
          tempfile_from(@config_file, content) do |temp|
            ::SCSSLint::Config.load(temp, merge_with_default: true)
          end
        end
      rescue ::SCSSLint::Exceptions::PluginGemLoadError => error
        raise ConfigDependencyError, error.message
      end

      def lints_to_violations(runner, file)
        runner.lints.map do |lint|
          linter_name = lint.linter&.name || 'undefined'
          Violation.new(
            file,
            Range.new(lint.location.line, lint.location.line),
            lint.description,
            linter_name
          )
        end
      end

      def new_runner(commit)
        require 'scss_lint'
        ::SCSSLint::Runner.new(config(commit))
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
