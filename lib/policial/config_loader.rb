module Policial
  # Public: Load and parse config files from GitHub repo.
  class ConfigLoader
    def initialize(commit)
      @commit = commit
    end

    def raw(filename)
      blank?(filename) ? '' : @commit.file_content(filename)
    end

    def json(filename)
      JSON.parse(raw(filename))
    rescue JSON::ParserError
      {}
    end

    def yaml(filename)
      YAML.load(raw(filename)) || {}
    rescue Psych::SyntaxError
      {}
    end

    private

    def blank?(string)
      string.to_s.strip.empty?
    end
  end
end
