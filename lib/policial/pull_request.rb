module Policial
  # Public: A GitHub Pull Request.
  class PullRequest
    attr_reader :repo, :number, :user
    attr_accessor :github_client

    def initialize(repo:, number:, head_sha:, github_client:, user: nil)
      @repo = repo
      @number = number
      @head_sha = head_sha
      @user = user
      @github_client = github_client
    end

    def comments
      @comments ||= fetch_comments
    end

    def files
      @files ||= @github_client.pull_request_files(
        @repo, @number
      ).map do |file|
        build_commit_file(file)
      end
    end

    def head_commit
      @head_commit ||= Commit.new(@repo, @head_sha, @github_client)
    end

    private

    def build_commit_file(file)
      CommitFile.new(file, head_commit)
    end

    def fetch_comments
      paginate do |page|
        @github_client.pull_request_comments(
          @repo,
          @number,
          page: page
        )
      end
    end

    private

    def paginate
      page = 1
      results = []

      until (page_results = yield(page)).empty?
        results += page_results
        page += 1
      end

      results
    end
  end
end
