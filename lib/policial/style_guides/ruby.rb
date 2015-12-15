require 'rubocop'

module Policial
  module StyleGuides
    # Public: Determine Ruby style guide violations per-line.
    class Ruby < Base
      def config_file(options = {})
        options[:rubocop_config] || RuboCop::ConfigLoader::DOTFILE
      end

      def violations_in_file(file)
        if config.file_to_exclude?(file.filename)
          []
        else
          team.inspect_file(parsed_source(file)).map do |offense|
            Violation.new(file, offense.line, offense.message, offense)
          end
        end
      end

      private

      def team
        cop_classes = RuboCop::Cop::Cop.all
        cop_classes.reject!(&:rails?) unless config['AllCops']['RunRailsCops']
        RuboCop::Cop::Team.new(cop_classes, config)
      end

      def parsed_source(file)
        absolute_path =
          File.join(config.base_dir_for_path_parameters, file.filename)
        RuboCop::ProcessedSource.new(file.content, absolute_path)
      end

      def config
        @config ||= RuboCop::ConfigLoader.merge_with_default(custom_config, '')
      end

      def custom_config
        custom = @repo_config.for(self)

        if custom.is_a?(Hash)
          RuboCop::Config.new(custom, '').tap(&:make_excludes_absolute)
        else
          RuboCop::Config.new
        end
      end
    end
  end
end
