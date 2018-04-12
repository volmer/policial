# frozen_string_literal: true

require 'rubocop'

module Policial
  module Linters
    # Public: Determine Ruby style guide violations per-line.
    class Ruby
      def initialize(config_file: RuboCop::ConfigLoader::DOTFILE)
        @config_file = config_file
      end

      def violations(file, config_loader)
        return [] unless include_file?(file.filename, config_loader)
        offenses =
          team(config_loader).inspect_file(parsed_source(file, config_loader))

        offenses_to_violations(offenses, file)
      end

      private

      def include_file?(filename, config_loader)
        return false if config(config_loader).file_to_exclude?(filename)
        File.extname(filename) == '.rb' ||
          config(config_loader).file_to_include?(filename)
      end

      def team(config_loader)
        cop_classes =
          if config(config_loader)['Rails']['Enabled']
            RuboCop::Cop::Registry.new(RuboCop::Cop::Cop.all)
          else
            RuboCop::Cop::Cop.non_rails
          end

        RuboCop::Cop::Team.new(
          cop_classes, config(config_loader), extra_details: true
        )
      end

      def parsed_source(file, config_loader)
        absolute_path = File.join(
          config(config_loader).base_dir_for_path_parameters, file.filename
        )

        RuboCop::ProcessedSource.new(
          file.content,
          config(config_loader).target_ruby_version,
          absolute_path
        )
      end

      def config(config_loader)
        @config ||= RuboCop::ConfigLoader.merge_with_default(
          custom_config(config_loader), ''
        )
      end

      def custom_config(config_loader)
        content = config_loader.yaml(@config_file)
        filter(content)

        tempfile_from(@config_file, content.to_yaml) do |tempfile|
          RuboCop::ConfigLoader.load_file(tempfile.path)
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

      def offenses_to_violations(offenses, file)
        offenses.reject(&:disabled?).map do |offense|
          Violation.new(
            file,
            Range.new(offense.location.first_line, offense.location.last_line),
            offense.message.strip,
            offense.cop_name
          )
        end
      end
    end
  end
end
