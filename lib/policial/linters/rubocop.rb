# frozen_string_literal: true

require 'rubocop'
require 'policial/linters/rubocop/corrector'
require 'policial/linters/rubocop/investigator'

module Policial
  module Linters
    # Public: Determine RuboCop style guide violations per-line.
    class RuboCop
      def initialize(config_file: ::RuboCop::ConfigLoader::DOTFILE)
        @config_file = config_file
      end

      def violations(file, commit)
        return [] unless include_file?(file.filename, commit)

        investigator = Investigator.new(file, config(commit))
        investigator.investigate
      end

      def correct(file, commit)
        return unless include_file?(file.filename, commit)

        corrector = Corrector.new(file, config(commit))
        corrector.correct
      end

      private

      def include_file?(filename, commit)
        return false if config(commit).file_to_exclude?(filename)

        File.extname(filename) == '.rb' ||
          config(commit).file_to_include?(filename)
      end

      def config(commit)
        @config ||= ::RuboCop::ConfigLoader.merge_with_default(
          custom_config(commit), ''
        )
      end

      def custom_config(commit)
        content = load_yaml(commit)
        filter(content)

        tempfile_from(@config_file, content.to_yaml) do |tempfile|
          ::RuboCop::ConfigLoader.load_file(tempfile.path)
        end
      rescue LoadError => error
        raise_dependency_error(error)
      end

      def tempfile_from(filename, content)
        filename = File.basename(filename)
        Tempfile.create(File.basename(filename), Dir.pwd) do |tempfile|
          tempfile.write(content)
          tempfile.rewind

          yield(tempfile)
        end
      end

      def filter(config_hash)
        config_hash.delete('inherit_gem')
        config_hash['inherit_from'] =
          Array(config_hash['inherit_from']).select do |value|
            value =~ /\A#{URI.regexp(%w[http https])}\z/
          end
      end

      def raise_dependency_error(error)
        pathname = Pathname.new(error.path)
        if pathname.absolute?
          pathname = pathname.relative_path_from(Pathname.pwd)
        end
        raise ConfigDependencyError, "Your RuboCop config #{@config_file} "\
          "requires #{pathname}, but it could not be loaded."
      end

      def load_yaml(commit)
        YAML.safe_load(
          commit.file_content(@config_file), [Regexp], [], false, @config_file
        ) || {}
      rescue Psych::SyntaxError => error
        raise InvalidConfigError, error.message
      end
    end
  end
end
