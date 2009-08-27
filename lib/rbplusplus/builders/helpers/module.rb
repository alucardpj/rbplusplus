module RbPlusPlus
  module Builders
    module ModuleHelpers

      # Build up any user-defined modules for this node
      def with_modules
        self.modules.each do |m|
          node = ModuleNode.new(m, m.name, m.node, m.modules, self)
          node.build
          nodes << node
        end
      end
      
      # Expose a function in this module
      def with_module_functions
      end

    end
  end
end
