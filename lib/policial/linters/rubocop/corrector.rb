# frozen_string_literal: true

require 'policial/linters/rubocop/operation'

module Policial
  module Linters
    # Public: Determine RuboCop style guide violations per-line.
    class RuboCop
      # Public: Corrects code style violations using RuboCop.
      class Corrector < Operation
        def correct
          source = parsed_source(@file.filename, @file.content)
          content = corrected_content(source)
          return if content == @file.content

          content
        end

        private

        def corrected_content(source)
          iterate_until_no_changes(source) do
            team = build_team(auto_correct: true)

            inspect_file(team, source)

            corrector = build_corrector(source, team)

            break if corrector.corrections.empty?

            new_content = corrector.rewrite
            break if new_content == source.raw_source

            source = parsed_source(@file.filename, new_content)
          end
          source.raw_source
        end

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

        def build_corrector(source, team)
          corrector = ::RuboCop::Cop::Corrector.new(source.buffer)
          skips = Set.new
          team.cops.each do |cop|
            next if cop.corrections.empty? || skips.include?(cop.class)

            corrections_on_changed_lines(cop, corrector)
            skips.merge(cop.class.autocorrect_incompatible_with)
          end
          corrector
        end

        def corrections_on_changed_lines(cop, corrector)
          cop.offenses.select(&:corrected?).each_with_index do |offense, index|
            next unless build_violation(offense).on_changed_line?

            corrector.corrections << cop.corrections[index]
          end
        end

        def inspect_file(team, source)
          team.inspect_file(source)
        rescue SystemStackError
          raise InfiniteCorrectionLoop
        end
      end
    end
  end
end
