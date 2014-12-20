require 'active_support/core_ext'

require 'policial/accusation_policy'
require 'policial/commenter'
require 'policial/commit'
require 'policial/commit_file'
require 'policial/github_api'
require 'policial/investigation'
require 'policial/line'
require 'policial/patch'
require 'policial/pull_request'
require 'policial/pull_request_event'
require 'policial/repo_config'
require 'policial/style_checker'
require 'policial/style_guides/base'
require 'policial/style_guides/ruby'
require 'policial/style_guides/unsupported'
require 'policial/unchanged_line'
require 'policial/version'
require 'policial/violation'

# Public: The global gem module. It exposes some module attribute accessors
# so you can configure GitHub credentials, enable/disable style guides
# and more.
module Policial
  STYLE_GUIDES = [Policial::StyleGuides::Ruby]
  # rubocop:disable Style/ClassVars

  mattr_accessor :github_access_token
  @@github_access_token = nil

  mattr_accessor :enabled_style_guides
  @@enabled_style_guides = STYLE_GUIDES

  def self.setup
    yield self
  end
end
