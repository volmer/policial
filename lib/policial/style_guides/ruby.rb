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
          offenses = team.inspect_file(parsed_source(file))
          offenses.map { |offense| Violation.new(file, offense) }
        end
      end

      private

      def team
        RuboCop::Cop::Team.new(RuboCop::Cop::Cop.all, config, rubocop_options)
      end

      def parsed_source(file)
        RuboCop::ProcessedSource.new(file.content, file.filename)
      end

      def config
        @config ||= RuboCop::ConfigLoader.merge_with_default(custom_config, '')
      end

      def custom_config
        custom = @repo_config.for(self)

        if custom.is_a?(Hash)
          RuboCop::Config.new(custom, '').tap do |config|
            config.add_missing_namespaces
            config.make_excludes_absolute
          end
        else
          RuboCop::Config.new
        end
      end

      def rubocop_options
        { debug: true } if config['ShowCopNames']
      end
    end
  end
end
