# frozen_string_literal: true

require 'policial/linters/rubocop/operation'

module Policial
  module Linters
    # Public: Determine RuboCop style guide violations per-line.
    class RuboCop
      # Public: Detects code style violations using RuboCop.
      class Investigator < Operation
        def investigate
          team = build_team
          source = parsed_source(@file.filename, @file.content)
          offenses = team.inspect_file(source)

          offenses_to_violations(offenses)
        end

        private

        def offenses_to_violations(offenses)
          offenses.reject(&:disabled?).map do |offense|
            build_violation(offense)
          end
        end
      end
    end
  end
end
