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
        head_sha: @payload['pull_request']['head']['sha'],
        head_ref: @payload['pull_request']['head']['ref'],
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
  end
end
