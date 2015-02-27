module Policial
  # Private: wraps accessors for the inner Octokit client.
  module OctokitClient
    def octokit=(client)
      Thread.current[:policial_octokit] = client
    end

    def octokit
      Thread.current[:policial_octokit] || Octokit
    end
  end
end
