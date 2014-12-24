require 'webmock/rspec'
require 'policial'

require 'support/helpers/github_api_helper'

RSpec.configure do |config|
  config.include(GitHubApiHelper)
  config.order = :random
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
