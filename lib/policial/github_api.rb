require 'octokit'
require 'base64'

module Policial
  # Public: Wrapper that ecapsulates all calls to GitHub.
  class GitHubApi
    delegate :create_pull_request_comment,
             :contents,
             :pull_request_files,
             to: :client

    def client
      @client ||= Octokit::Client.new(
        access_token: Policial.github_access_token, auto_paginate: true
      )
    end

    def pull_request_comments(repo, number)
      paginate do |page|
        client.pull_request_comments(
          repo,
          number,
          page: page
        )
      end
    end

    private

    def paginate
      page, results, all_pages_fetched = 1, [], false

      until all_pages_fetched
        if (page_results = yield(page)).empty?
          all_pages_fetched = true
        else
          results += page_results
          page += 1
        end
      end

      results
    end
  end
end
