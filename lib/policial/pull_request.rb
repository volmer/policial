# frozen_string_literal: true

module Policial
  # Public: A GitHub Pull Request.
  class PullRequest
    attr_reader :repo, :number, :user
    attr_accessor :github_client

    def initialize(repo:, number:, head:, github_client:, user: nil)
      @repo = repo
      @number = number
      @head = head
      @user = user
      @github_client = github_client
    end

    def files
      @files ||= @github_client.pull_request_files(
        @repo, @number
      ).map do |file|
        build_commit_file(file)
      end.tap(&method(:check_limits))
    end

    def head_commit
      @head_commit ||=
        Commit.new(@repo, @head[:sha], @head[:branch], @github_client)
    end

    private

    def check_limits(_files)
      LimitsChecker.new(github_client: @github_client).check
    end

    def build_commit_file(file)
      CommitFile.new(file, head_commit)
    end
  end
end
