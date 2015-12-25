require 'rubocop'

module Policial
  module StyleGuides
    # Public: Determine Ruby style guide violations per-line.
    class Ruby < Base
      KEY = :ruby

      def violations_in_file(file)
        team.inspect_file(parsed_source(file)).map do |offense|
          Violation.new(file, offense.line, offense.message, offense.cop_name)
        end
      end

      def exclude_file?(filename)
        config.file_to_exclude?(filename)
      end

      def filename_pattern
        /.+\.rb\z/
      end

      def default_config_file
        RuboCop::ConfigLoader::DOTFILE
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
        content = @config_loader.raw(config_file)

        tempfile_from(config_file, content) do |tempfile|
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
    end
  end
end
