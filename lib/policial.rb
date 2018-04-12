# frozen_string_literal: true

require 'octokit'

require 'policial/commit'
require 'policial/commit_file'
require 'policial/detective'
require 'policial/errors'
require 'policial/limits_checker'
require 'policial/line'
require 'policial/patch'
require 'policial/pull_request'
require 'policial/pull_request_event'
require 'policial/style_checker'
require 'policial/linters/coffeelint'
require 'policial/linters/eslint'
require 'policial/linters/rubocop'
require 'policial/linters/scss_lint'
require 'policial/unchanged_line'
require 'policial/version'
require 'policial/violation'

# Public: The global gem module.
module Policial
end
