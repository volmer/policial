# frozen_string_literal: true

module Policial
  # Public: A Commit in a GitHub repo.
  class Commit
    attr_reader :repo, :sha, :branch

    def initialize(repo, sha, branch, github_client)
      @repo = repo
      @sha  = sha
      @branch = branch
      @github_client = github_client
    end

    def file_content(filename)
      with_octokit_error_handling do
        decode(file_content_response(filename))
      end
    end

    def file_download_url(filename)
      with_octokit_error_handling do
        file_content_response(filename).download_url
      end
    end

    private

    def with_octokit_error_handling
      yield
    rescue Octokit::NotFound
      ''
    rescue Octokit::Forbidden => error
      return '' if
        error.errors.any? && error.errors.first[:code] == 'too_large'

      raise error
    end

    def file_content_response(filename)
      @github_client.contents(@repo, path: filename, ref: @sha)
    end

    def decode(content)
      if content&.content
        Base64.decode64(content.content).force_encoding('UTF-8')
      else
        ''
      end
    end
  end
end
