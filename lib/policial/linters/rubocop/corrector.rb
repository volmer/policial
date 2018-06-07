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

            new_content = autocorrect_all_cops(source.buffer, team)
            break if new_content == source.raw_source

            source = parsed_source(@file.filename, new_content)
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

        def autocorrect_all_cops(buffer, team)
          corrector = ::RuboCop::Cop::Corrector.new(buffer)

          collate_corrections(corrector, team)

          if !corrector.corrections.empty?
            corrector.rewrite
          else
            buffer.source
          end
        end

        def collate_corrections(corrector, team)
          skips = Set.new

          team.cops.select(&:autocorrect?).each do |cop|
            next if cop.corrections.empty?
            next if skips.include?(cop.class)

            corrector.corrections.concat(cop.corrections)
            skips.merge(cop.class.autocorrect_incompatible_with)
          end
        end
      end
    end
  end
end
