module Policial
  # Public: Hold file, line, and message. Built by style guides.
  class Violation
    attr_reader :line, :line_number, :filename, :offense

    def initialize(file, offense)
      @filename    = file.filename
      @line        = file.line_at(offense.line)
      @line_number = offense.line
      @offense     = offense
    end

    def message
      @offense.message
    end

    def patch_position
      @line.patch_position
    end

    def on_changed_line?
      @line.changed?
    end
  end
end
