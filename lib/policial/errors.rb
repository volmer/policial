# frozen_string_literal: true

module Policial
  class LinterError < StandardError; end
  class ConfigDependencyError < StandardError; end
  class IncompleteResultsError < StandardError; end
  class InfiniteCorrectionLoop < StandardError; end
end
