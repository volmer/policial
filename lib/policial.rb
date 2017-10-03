# frozen_string_literal: true

require 'octokit'

require 'policial/commit'
require 'policial/commit_file'
require 'policial/config_loader'
require 'policial/detective'
require 'policial/errors'
require 'policial/limits_checker'
require 'policial/line'
require 'policial/patch'
require 'policial/pull_request'
require 'policial/pull_request_event'
require 'policial/style_checker'
require 'policial/linters/base'
require 'policial/linters/ruby'
require 'policial/linters/scss'
require 'policial/linters/coffeescript'
require 'policial/linters/javascript'
require 'policial/unchanged_line'
require 'policial/version'
require 'policial/violation'

# Public: The global gem module. It exposes some module attribute accessors
# so you can configure GitHub credentials, enable/disable linters
# and more.
module Policial
  DEFAULT_LINTERS = [
    Policial::Linters::Ruby,
    Policial::Linters::CoffeeScript,
    Policial::Linters::JavaScript
  ].freeze

  OPTIONAL_LINTERS = [
    Policial::Linters::Scss
  ].freeze

  module_function

  def linters
    @linters ||= DEFAULT_LINTERS.dup
  end

  def linters=(linters)
    @linters = linters
  end
end
