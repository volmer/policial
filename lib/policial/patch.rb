# frozen_string_literal: true

module Policial
  # Public: a chunk of changed code in a commit file.
  class Patch
    RANGE_INFORMATION_LINE = /^@@ .+\+(?<line_number>\d+),/
    MODIFIED_LINE = /^\+(?!\+|\+)/
    NOT_REMOVED_LINE = /^[^-]/

    def initialize(body)
      @body = body || ''
    end

    def changed_lines
      line_number = 0

      @body.lines.each_with_index.with_object([]) do |(line, patch_pos), lines|
        line_number =
          parse_line(line, line_number, patch_pos, lines) || line_number
      end
    end

    private

    def parse_line(line_content, line_number, patch_position, lines)
      case line_content
      when RANGE_INFORMATION_LINE
        Regexp.last_match[:line_number].to_i
      when MODIFIED_LINE
        lines << Line.new(line_number, line_content, patch_position)
        line_number + 1
      when NOT_REMOVED_LINE
        line_number + 1
      end
    end
  end
end
