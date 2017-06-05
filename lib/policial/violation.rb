# frozen_string_literal: true

module Policial
  # Public: Hold file, line, and message. Built by linters.
  class Violation
    attr_reader :line_number, :message, :linter

    def initialize(file, line_number, message, linter)
      @file        = file
      @line_number = line_number
      @message     = message
      @linter      = linter
    end

    def filename
      @file.filename
    end

    def line
      @line ||= @file.line_at(line_number)
    end

    def patch_position
      line.patch_position
    end

    def on_changed_line?
      line.changed?
    end
  end
end
