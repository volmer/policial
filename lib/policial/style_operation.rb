# frozen_string_literal: true

module Policial
  class StyleOperation
    def initialize(pull_request, options = {})
      @options = options
      @pull_request = pull_request
      @linters = {}
    end

    private

    def files_to_check
      @pull_request.files.reject(&:removed?)
    end

    def linters
      Policial.linters.map do |klass|
        @linters[klass] ||= klass.new(
          config_loader, @options[klass::KEY] || {}
        )
      end
    end

    def config_loader
      @config_loader ||= ConfigLoader.new(@pull_request.head_commit)
    end
  end
end
