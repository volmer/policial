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
        @payload['repository']['full_name'],
        @payload['number'],
        @payload['pull_request']['head']['sha']
      )
    end

    def action
      @payload['action']
    end
  end
end
