require 'json'

module Policial
  # Public: Parses a pull request event payload.
  class PullRequestEvent
    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def pull_request
      @pull_request ||= PullRequest.new(
        repo: @payload['repository']['full_name'],
        number: @payload['number'],
        head_sha: @payload['pull_request']['head']['sha'],
        user: @payload['pull_request']['user']['login']
      )
    end

    def action
      @payload['action']
    end
  end
end
