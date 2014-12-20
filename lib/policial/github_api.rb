require 'octokit'
require 'base64'

module Policial
  # Public: Wrapper that ecapsulates all calls to GitHub.
  class GitHubApi
    delegate :contents,
             :create_pull_request_comment,
             :pull_request_comments,
             :pull_request_files,
             to: :client

    def client
      @client ||= Octokit::Client.new(
        access_token: Policial.github_access_token, auto_paginate: true
      )
    end
  end
end
