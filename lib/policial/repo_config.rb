module Policial
  # Public: Load and parse config files from GitHub repo.
  class RepoConfig
    def initialize(commit)
      @commit = commit
    end

    def enabled_for?(style_guide_class)
      Policial::STYLE_GUIDES.include?(style_guide_class)
    end

    def for(style_guide_class)
      config_file = style_guide_class.config_file

      if config_file
        load_file(config_file)
      else
        {}
      end
    end

    private

    def load_file(file)
      config_file_content = @commit.file_content(file)

      parse_yaml(config_file_content) || {}
    end

    def parse_yaml(content)
      YAML.load(content)
    rescue Psych::SyntaxError
      {}
    end
  end
end
