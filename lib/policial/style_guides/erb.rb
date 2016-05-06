# frozen_string_literal: true

# require 'erb-lint'

module Policial
  module StyleGuides
    # Public: Determine ERB style guide violations per-line.
    class ERB < Base
      KEY = :erb

      def violations_in_file(file)
        errors = ERBLint.lint(file.content, config)
        violations(file, errors)
      end

      def exclude_file?(_filename)
        false
      end

      def filename_pattern
        /.+\.html\.erb\z/
      end

      def default_config_file
        '.erb-lint.yml'
      end

      private

      def config
        @config ||= begin
          content = @config_loader.yaml(config_file)
          content.empty? ? :defaults : content
        end
      end

      def violations(file, errors)
        errors.map do |error|
          Violation.new(
            file, error[:line], error[:message], error[:ruleId])
        end
      end
    end
  end
end

# Public: Runs the linters against the file.
class ERBLint
  # https://www.w3.org/TR/html5/syntax.html#attributes
  @@attribute_name = /[^\s"'>\/=]+/ # attribute names must be non empty and can't have a certain set of special characters
  @@attribute_value = /"([^"]*)"|'([^']*)'|([^\s"'=<>`]+)/ # attribute values can be double-quoted OR single-quoted OR unquoted
  @@attribute_pattern = /#{@@attribute_name}(\s*=\s*(#{@@attribute_value}))?/ # attributes can be empty or have an attribute value

  # https://www.w3.org/TR/html5/syntax.html#syntax-start-tag
  @@tag_name_pattern = /[A-Za-z0-9]+/ # maybe add _ < ? etc later since it gets interpreted by some browsers
  @@start_tag_pattern = /<#{@@tag_name_pattern}(\s+(#{@@attribute_pattern}\s*)*)?\/?>/ # start tag must have a space after tag name if attributes exist. /> or > to end the tag.

  @@class_attr_name_pattern = /\Aclass\z/i #attribute names are case-insensitive

  legacy_classes = [
    'pp',
    'ico',
    'ico-[\w-]*'
  ].map {|class_name| /\A#{class_name}\z/}.freeze
  @@legacy_class_pattern = /#{legacy_classes.join("|")}/ # class names are case sensitive

  def self.lint(file_content, config)
    errors = []

    lines = file_content.split("\n")
    lines.each_with_index do |line, index|
      p "Line #{index + 1}: #{line}"
      start_tags = line.scan(/(#{@@start_tag_pattern})/)
      start_tags.each do |start_tag|
        attributes_string = start_tag[1]

        attributes_string.scan(/(#{@@attribute_pattern})/).map do |attribute_matching_group| # first matching group is attributes string
          entire_string = attribute_matching_group[0]
          value_with_equal_sign = attribute_matching_group[1]
          value = attribute_matching_group[3..5].reduce {|a, b| a.nil? ? b : a} # get first non-nil matching for value

          p attribute = {
            name: entire_string.split(value_with_equal_sign)[0],
            value: value
          }

          if @@class_attr_name_pattern.match(attribute[:name])
            attribute[:value].split(" ").each do |class_name|
              unless (legacy_class_match = @@legacy_class_pattern.match(class_name)).nil?
                error = {
                  line: index + 1,
                  message: "Legacy class `#{legacy_class_match[0]}` detected.",
                  ruleId: 'LegacyClass'
                }
                errors.push(error)
              end
            end
          end
        end
      end
    end
    errors
  end
end
