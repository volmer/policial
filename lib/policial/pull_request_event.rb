# frozen_string_literal: true

require 'json'

module Policial
  # Public: Parses a pull request event payload.
  class PullRequestEvent
    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def pull_request_attributes
      {
        repo: @payload['repository']['full_name'],
        number: @payload['number'],
        head: head,
        user: @payload['pull_request']['user']['login']
      }
    rescue NoMethodError
      nil
    end

    def should_investigate?
      !pull_request_attributes.nil? && (
        @payload['action'] == 'opened' || @payload['action'] == 'synchronize'
      )
    end

    private

    def head
      {
        sha: @payload['pull_request']['head']['sha'],
        branch: @payload['pull_request']['head']['ref']
      }
    end
  end
end
