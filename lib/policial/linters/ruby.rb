# frozen_string_literal: true

require 'rubocop'

module Policial
  module Linters
    # Public: Determine Ruby style guide violations per-line.
    class Ruby < Base
      KEY = :ruby

      class InfiniteCorrectionLoop < LinterError; end

      def violations_in_file(file)
        offenses = build_team.inspect_file(parsed_source(file))

        offenses.reject(&:disabled?).map do |offense|
          build_violation(file, offense)
        end
      end

      def autocorrect(file)
        source = parsed_source(file)

        iterate_until_no_changes(file, source) do
          team = build_team(auto_correct: true)
          team.inspect_file(source)
          corrector = RuboCop::Cop::Corrector.new(source.buffer)
          collate_corrections(file, corrector, team)

          break if corrector.corrections.empty?
          new_content = corrector.rewrite
          break if new_content == source.raw_source

          source = parsed_source(file, content: new_content)
        end

        source.raw_source
      end

      def include_file?(filename)
        return false if config.file_to_exclude?(filename)
        File.extname(filename) == '.rb' || config.file_to_include?(filename)
      end

      def default_config_file
        RuboCop::ConfigLoader::DOTFILE
      end

      private

      def iterate_until_no_changes(file, source)
        processed_sources = []
        iterations = 0

        loop do
          if processed_sources.include?(source.checksum)
            raise InfiniteCorrectionLoop,
                  "Detected correction loop for #{file.filename}"
          else
            processed_sources << source.checksum
          end

          if (iterations += 1) > RuboCop::Runner::MAX_ITERATIONS
            raise InfiniteCorrectionLoop,
                  "Stopping after #{iterations} iterations for #{file.filename}"
          end

          break unless (source = yield)
        end
      end

      def build_violation(file, offense)
        Violation.new(
          file,
          Range.new(offense.location.first_line, offense.location.last_line),
          offense.message.strip,
          offense.cop_name
        )
      end

      def collate_corrections(file, corrector, team)
        skips = Set.new
        team.cops.each do |cop|
          next if cop.corrections.empty? || skips.include?(cop.class)

          cop.offenses.select(&:corrected?).each_with_index do |offense, index|
            next unless build_violation(file, offense).on_changed_line?

            corrector.corrections << cop.corrections[index]
            skips.merge(cop.class.autocorrect_incompatible_with)
          end
        end
      end

      def build_team(auto_correct: false)
        cop_classes = if config['Rails']['Enabled']
                        RuboCop::Cop::Registry.new(RuboCop::Cop::Cop.all)
                      else
                        RuboCop::Cop::Cop.non_rails
                      end

        RuboCop::Cop::Team.new(
          cop_classes,
          config,
          extra_details: true,
          auto_correct: auto_correct,
          stdin: ''
        )
      end

      def parsed_source(file, content: nil)
        absolute_path =
          File.join(config.base_dir_for_path_parameters, file.filename)

        RuboCop::ProcessedSource.new(
          content || file.content,
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
        raise ConfigDependencyError, "Your RuboCop config #{config_file} "\
          "requires #{pathname}, but it could not be loaded."
      end
    end
  end
end
