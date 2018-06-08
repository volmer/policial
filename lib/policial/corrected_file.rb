# frozen_string_literal: true

module Policial
  # Public: A new version of a file that had its contents corrected.
  class CorrectedFile
    attr_reader :original, :content

    def initialize(original, content)
      @original = original
      @content = content
    end

    def filename
      @original.filename
    end
  end
end
