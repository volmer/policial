# frozen_string_literal: true

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
            Violation.new(
              @file,
              Range.new(
                offense.location.first_line, offense.location.last_line
              ),
              offense.message.strip,
              offense.cop_name
            )
          end
        end
      end
    end
  end
end
