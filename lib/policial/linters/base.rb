# frozen_string_literal: true

module Policial
  module Linters
    # Public: Base to contain common linter logic.
    class Base
      def initialize(config_loader, options = {})
        @config_loader = config_loader
        @options = options
      end

      def violations_in_file(_file)
        raise NotImplementedError, "must implement ##{__method__}"
      end

      def inlcude_file?(_filename)
        raise NotImplementedError, "must implement ##{__method__}"
      end

      def default_config_file
        raise NotImplementedError, "must implement ##{__method__}"
      end

      def config_file
        if @options[:config_file].to_s.strip.empty?
          default_config_file
        else
          @options[:config_file]
        end
      end

      def investigate?(filename)
        enabled? && include_file?(filename)
      end

      class << self
        def supports_autocorrect?
          method_defined?(:autocorrect)
        end
      end

      private

      def enabled?
        @options[:enabled] != false
      end
    end
  end
end
