require 'rubocop'

module Policial
  module StyleGuides
    # Public: Determine Ruby style guide violations per-line.
    class Ruby < Base
      KEY = :ruby

      def violations_in_file(file)
        return [] if ignore?(file.filename)
        team.inspect_file(parsed_source(file)).map do |offense|
          Violation.new(file, offense.line, offense.message, offense.cop_name)
        end
      end

      private

      def config_file
        if @options[:rubocop_config].to_s.strip.empty?
          RuboCop::ConfigLoader::DOTFILE
        else
          @options[:rubocop_config]
        end
      end

      def ignore?(filename)
        (filename =~ /.+\.rb\z/).nil? || config.file_to_exclude?(filename)
      end

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
        custom = @config_loader.yaml(config_file)

        if custom.is_a?(Hash)
          RuboCop::Config.new(custom, '').tap(&:make_excludes_absolute)
        else
          RuboCop::Config.new
        end
      end
    end
  end
end
