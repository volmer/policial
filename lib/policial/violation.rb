module Policial
  # Public: Hold file, line, and violation message values. Built by style
  # guides.
  class Violation
    attr_reader :line_number, :filename, :offenses

    def initialize(file, offense)
      @filename    = file.filename
      @line        = file.line_at(offense.line)
      @line_number = offense.line
      @offenses    = [offense]
    end

    def add_offense(offense)
      @offenses << offense
    end

    def messages
      @offenses.map(&:message).uniq
    end

    def patch_position
      @line.patch_position
    end

    def on_changed_line?
      @line.changed?
    end
  end
end
