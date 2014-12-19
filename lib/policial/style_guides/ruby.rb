require 'rubocop'

module Policial
  module StyleGuides
    # Public: Determine Ruby style guide violations per-line.
    class Ruby < Base
      CONFIG_FILE = {
        path: '.rubocop.yml',
        type: 'yaml'
      }

      def violations_in_file(file)
        if config.file_to_exclude?(file.filename)
          []
        else
          team.inspect_file(parsed_source(file)).map do |violation|
            Violation.new(file, violation.line, violation.message)
          end
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
        RuboCop::Config.new(@repo_config.for(self), '').tap do |config|
          config.add_missing_namespaces
          config.make_excludes_absolute
        end
      rescue NoMethodError
        RuboCop::Config.new
      end

      def rubocop_options
        { debug: true } if config['ShowCopNames']
      end
    end
  end
end
