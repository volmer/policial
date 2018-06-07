# frozen_string_literal: true

module Policial
  module Linters
    # Public: Determine RuboCop style guide violations per-line.
    class RuboCop
      # Public: Determine RuboCop style guide violations per-line.
      class Operation
        def initialize(file, config)
          @file = file
          @config = config
          @options = { extra_details: true, stdin: '' }
        end

        private

        def build_team(auto_correct: false)
          cop_classes =
            if @config['Rails']['Enabled']
              ::RuboCop::Cop::Registry.new(::RuboCop::Cop::Cop.all)
            else
              ::RuboCop::Cop::Cop.non_rails
            end

          @options[:auto_correct] = auto_correct

          ::RuboCop::Cop::Team.new(cop_classes, @config, @options)
        end

        def parsed_source(filename, content)
          absolute_path = File.join(
            @config.base_dir_for_path_parameters, filename
          )

          ::RuboCop::ProcessedSource.new(
            content,
            @config.target_ruby_version,
            absolute_path
          )
        end
      end
    end
  end
end
