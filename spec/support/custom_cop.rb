# frozen_string_literal: true
module TestSupport
  # Custom cop for test purposes
  class CustomCop < RuboCop::Cop::Cop
    def on_ivasgn(node)
      name, = *node
      return unless name.to_s.include?('fuck')
      add_offense(node, node.loc.name, 'No swearwords!')
    end
  end
end
