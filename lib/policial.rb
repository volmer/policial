# frozen_string_literal: true

require 'octokit'

require 'policial/cli'
require 'policial/commit'
require 'policial/commit_file'
require 'policial/config_loader'
require 'policial/detective'
require 'policial/line'
require 'policial/patch'
require 'policial/pull_request'
require 'policial/pull_request_event'
require 'policial/style_checker'
require 'policial/style_guides/base'
require 'policial/style_guides/ruby'
require 'policial/style_guides/scss'
require 'policial/style_guides/coffeescript'
require 'policial/unchanged_line'
require 'policial/version'
require 'policial/violation'

# Public: The global gem module. It exposes some module attribute accessors
# so you can configure GitHub credentials, enable/disable style guides
# and more.
module Policial
  DEFAULT_STYLE_GUIDES = [
    Policial::StyleGuides::Ruby,
    Policial::StyleGuides::CoffeeScript
  ].freeze

  OPTIONAL_STYLE_GUIDES = [
    Policial::StyleGuides::Scss
  ].freeze

  module_function

  def style_guides
    @style_guides ||= DEFAULT_STYLE_GUIDES.dup
  end

  def style_guides=(style_guides)
    @style_guides = style_guides
  end
end
