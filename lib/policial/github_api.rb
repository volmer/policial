require 'octokit'
require 'base64'

module Policial
  # Public: Wrapper that ecapsulates all calls to GitHub.
  class GithubApi
    def client
      @client ||= Octokit::Client.new(
        access_token: Policial.github_access_token, auto_paginate: true
      )
    end

    def repo(repo_name)
      client.repository(repo_name)
    end

    def add_pull_request_comment(options)
      client.create_pull_request_comment(
        options[:commit].repo_name,
        options[:pull_request_number],
        options[:comment],
        options[:commit].sha,
        options[:filename],
        options[:patch_position]
      )
    end

    def pull_request_comments(full_repo_name, pull_request_number)
      paginate do |page|
        client.pull_request_comments(
          full_repo_name,
          pull_request_number,
          page: page
        )
      end
    end

    def pull_request_files(full_repo_name, number)
      client.pull_request_files(full_repo_name, number)
    end

    def file_contents(full_repo_name, filename, sha)
      client.contents(full_repo_name, path: filename, ref: sha)
    end

    def user_teams
      client.user_teams
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
