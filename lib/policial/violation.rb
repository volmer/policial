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
      @lines ||= @file.content.split("\n", -1)[@line_range]
    end

    def on_changed_line?
      patch_lines.any?(&:changed?)
    end

    private

    def patch_lines
      @patch_lines ||= @line_range.map do |line_number|
        @file.line_at(line_number)
      end
    end
  end
end
