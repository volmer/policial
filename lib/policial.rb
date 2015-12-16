require 'octokit'

require 'policial/commit'
require 'policial/commit_file'
require 'policial/detective'
require 'policial/line'
require 'policial/patch'
require 'policial/pull_request'
require 'policial/pull_request_event'
require 'policial/repo_config'
require 'policial/style_checker'
require 'policial/style_guides/base'
require 'policial/style_guides/ruby'
require 'policial/style_guides/scss'
require 'policial/style_guides/coffeescript'
require 'policial/style_guides/unsupported'
require 'policial/unchanged_line'
require 'policial/version'
require 'policial/violation'

# Public: The global gem module. It exposes some module attribute accessors
# so you can configure GitHub credentials, enable/disable style guides
# and more.
module Policial
  STYLE_GUIDES = [Policial::StyleGuides::Ruby, Policial::StyleGuides::Scss, Policial::StyleGuides::Coffeescript]
end
