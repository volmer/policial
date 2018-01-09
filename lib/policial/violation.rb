# frozen_string_literal: true

module Policial
  # Public: Hold file, line range, and message. Built by linters.
  class Violation
    attr_reader :line_range, :message, :linter

    def initialize(file, line_range, message, linter)
      @file        = file
      @line_range  = line_range
      @message     = message
      @linter      = linter
    end

    def filename
      @file.filename
    end

    def lines
      @lines ||= @line_range.map { |line_number| @file.line_at(line_number) }
    end

    def on_changed_line?
      lines.any? { |line| line.changed? }
    end
  end
end
