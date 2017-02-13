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
      decode(@github_client.contents(@repo, path: filename, ref: @sha))
    rescue Octokit::NotFound
      ''
    rescue Octokit::Forbidden => error
      return '' if error.errors.any? && error.errors.first[:code] == 'too_large'
      raise error
    end

    private

    def decode(content)
      if content&.content
        Base64.decode64(content.content).force_encoding('UTF-8')
      else
        ''
      end
    end
  end
end
