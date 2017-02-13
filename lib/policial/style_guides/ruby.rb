# frozen_string_literal: true

require 'rubocop'

module Policial
  module StyleGuides
    # Public: Determine Ruby style guide violations per-line.
    class Ruby < Base
      KEY = :ruby

      def violations_in_file(file)
        offenses = team.inspect_file(parsed_source(file))

        offenses.reject(&:disabled?).map do |offense|
          Violation.new(
            file, offense.line, offense.message.strip, offense.cop_name
          )
        end
      end

      def include_file?(filename)
        return false if config.file_to_exclude?(filename)
        File.extname(filename) == '.rb' || config.file_to_include?(filename)
      end

      def default_config_file
        RuboCop::ConfigLoader::DOTFILE
      end

      private

      def team
        cop_classes = if config['Rails']['Enabled']
                        RuboCop::Cop::Registry.new(RuboCop::Cop::Cop.all)
                      else
                        RuboCop::Cop::Cop.non_rails
                      end

        RuboCop::Cop::Team.new(cop_classes, config, extra_details: true)
      end

      def parsed_source(file)
        absolute_path =
          File.join(config.base_dir_for_path_parameters, file.filename)

        RuboCop::ProcessedSource.new(
          file.content,
          config.target_ruby_version,
          absolute_path
        )
      end

      def config
        @config ||= RuboCop::ConfigLoader.merge_with_default(custom_config, '')
      end

      def custom_config
        content = @config_loader.yaml(config_file)
        filter(content)

        tempfile_from(config_file, content.to_yaml) do |tempfile|
          RuboCop::ConfigLoader.load_file(tempfile.path)
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

      def filter(config_hash)
        config_hash.delete('require')
        config_hash.delete('inherit_gem')
        config_hash['inherit_from'] =
          Array(config_hash['inherit_from']).select do |value|
            value =~ /\A#{URI.regexp(%w(http https))}\z/
          end
      end
    end
  end
end
