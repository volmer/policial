module Policial
  module StyleGuides
    # Public: Returns empty set of violations.
    class Unsupported < Base
      def violations_in_file(_)
        []
      end
    end
  end
end
