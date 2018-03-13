# frozen_string_literal: true

module Policial
  # Hold file and corrected content.
  class CorrectedFile
    attr_reader :content

    def initialize(file, content)
      @file    = file
      @content = content
    end

    def filename
      @file.filename
    end

    def uncorrected_content
      @file.content
    end

    def sha
      @file.sha
    end
  end
end
