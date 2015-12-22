module Policial
  module StyleGuides
    # Public: Base to contain common style guide logic.
    class Base
      def initialize(config_loader, options = {})
        @config_loader = config_loader
        @options = options
      end

      def violations_in_file(_file)
        fail NotImplementedError, "must implement ##{__method__}"
      end
    end
  end
end
