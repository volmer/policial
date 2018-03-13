# frozen_string_literal: true

module Policial
  # Public: A file in a commit.
  class CommitFile
    attr_reader :commit

    def initialize(file, commit)
      @file   = file
      @commit = commit
    end

    def sha
      @file.sha
    end

    def filename
      @file.filename
    end

    def content
      @content ||= begin
        @commit.file_content(filename) unless removed?
      end
    end

    def removed?
      @file.status == 'removed'
    end

    def line_at(line_number)
      changed_lines.detect { |line| line.number == line_number } ||
        UnchangedLine.new
    end

    private

    def changed_lines
      @changed_lines ||= patch.changed_lines
    end

    def patch
      Patch.new(@file.patch)
    end
  end
end
