module Policial
  # Public: A GibHub Pull Request.
  class PullRequest
    attr_reader :repo, :number

    def initialize(repo, number, head_sha)
      @repo     = repo
      @number   = number
      @head_sha = head_sha
    end

    def comments
      @comments ||= api.pull_request_comments(@repo, @number)
    end

    def files
      @files ||= api.pull_request_files(@repo, @number).map do |file|
        build_commit_file(file)
      end
    end

    def head_commit
      @head_commit ||= Commit.new(@repo, @head_sha, api)
    end

    private

    def build_commit_file(file)
      CommitFile.new(file, head_commit)
    end

    def api
      @api ||= Policial::GitHubApi.new
    end
  end
end
