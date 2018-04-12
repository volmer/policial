# frozen_string_literal: true

require 'scss_lint'

module Policial
  module Linters
    # Public: Determine SCSS style guide violations per-line.
    class Scss
      def initialize(config_file: SCSSLint::Config::FILE_NAME)
        @config_file = config_file
      end

      def violations(file, config_loader)
        return [] unless include_file?(file.filename, config_loader)

        absolute_path = File.expand_path(file.filename)

        runner = new_runner(config_loader)

        tempfile_from(file.filename, file.content) do |tempfile|
          runner.run([{ file: tempfile, path: absolute_path }])
        end

        lints_to_violations(runner, file)
      rescue SCSSLint::Exceptions::LinterError => error
        raise LinterError, error.message
      end

      private

      def include_file?(filename, config_loader)
        File.extname(filename) == '.scss' &&
          !config(config_loader).excluded_file?(File.expand_path(filename))
      end

      def config(config_loader)
        @config ||= begin
          content = config_loader.raw(@config_file)
          tempfile_from(@config_file, content) do |temp|
            SCSSLint::Config.load(temp, merge_with_default: true)
          end
        end
      rescue SCSSLint::Exceptions::PluginGemLoadError => error
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

      def new_runner(config_loader)
        SCSSLint::Runner.new(config(config_loader))
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
