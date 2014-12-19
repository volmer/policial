module Policial
  # Public: An unchanged line in a commit file.
  class UnchangedLine
    def initialize(*)
    end

    def patch_position
      -1
    end

    def changed?
      false
    end
  end
end
