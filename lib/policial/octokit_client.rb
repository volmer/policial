module Policial
  # Private: wraps accessors for the inner Octokit client.
  module OctokitClient
    attr_writer :octokit

    def octokit
      @octokit || Octokit
    end
  end
end
