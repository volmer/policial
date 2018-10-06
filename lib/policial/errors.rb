# frozen_string_literal: true

module Policial
  class Error < StandardError; end

  class LinterError < Error; end
  class IncompleteResultsError < Error; end
  class InfiniteCorrectionLoop < Error; end

  class ConfigError < Error; end
  class ConfigDependencyError < ConfigError; end
  class InvalidConfigError < ConfigError; end
end
