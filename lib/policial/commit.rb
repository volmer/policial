# frozen_string_literal: true

module Policial
  # Public: A Commit in a GitHub repo.
  class Commit
    attr_reader :repo, :sha

    def initialize(repo, sha, github_client)
      @repo = repo
      @sha  = sha
      @github_client = github_client
    end

    def file_content(filename)
      contents = @github_client.contents(@repo, path: filename, ref: @sha)

      if contents&.content
        Base64.decode64(contents.content).force_encoding('UTF-8')
      else
        ''
      end
    rescue Octokit::NotFound
      ''
    end
  end
end
