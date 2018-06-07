# frozen_string_literal: true

module Policial
  module Linters
    # Public: Determine RuboCop style guide violations per-line.
    class RuboCop
      # Public: Determine RuboCop style guide violations per-line.
      class Corrector < Operation
        def correct
          source = parsed_source(@file.filename, @file.content)

          iterate_until_no_changes(source) do
            team = build_team(auto_correct: true)

            team.inspect_file(source)
            break unless team.updated_source_file?
            source = parsed_source(@file.filename, @options[:stdin])
          end

          source.raw_source
        end

        private

        def iterate_until_no_changes(source)
          @sources = []

          iterations = 0

          loop do
            check_for_infinite_loop(source)

            if (iterations += 1) > ::RuboCop::Runner::MAX_ITERATIONS
              raise InfiniteCorrectionLoop
            end

            source = yield
            break unless source
          end
        end

        def check_for_infinite_loop(source)
          checksum = source.checksum

          raise InfiniteCorrectionLoop if @sources.include?(checksum)

          @sources << checksum
        end
      end
    end
  end
end
