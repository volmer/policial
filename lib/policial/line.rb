# frozen_string_literal: true

module Policial
  # Public: a changed line in a commit file.
  class Line
    attr_reader :content, :number, :patch_position

    def initialize(number, content, patch_position)
      @number         = number
      @content        = content
      @patch_position = patch_position
    end

    def changed?
      true
    end
  end
end
