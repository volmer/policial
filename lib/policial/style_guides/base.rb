module Policial
  module StyleGuides
    # Public: Base to contain common style guide logic.
    class Base
      def initialize(repo_config)
        @repo_config = repo_config
      end

      def violations_in_file(_file)
        fail NotImplementedError, "must implement ##{__method__}"
      end
    end
  end
end
