module RbPlusPlus
  module Builders

    # Base class for all code generation nodes
    #
    # A Node is simply a handler for one complete statement or block of C++ code.
    #
    # The code generation system for Rb++ is a two step process.
    # We first, starting with an ExtensionNode, build up an internal representation
    # of the resulting code, setting up all the code nodes required for proper
    # wrapping of the library.
    #
    # Once that's in place, then we run through the tree, actually generating
    # the C++ wrapper code.
    class Base

      # List of includes for this node
      attr_accessor :includes

      # List of declaration nodes for this node
      attr_accessor :declarations

      # List of registeration nodes for this node
      attr_accessor :registrations

      # Link to the parent node of this node
      attr_accessor :parent

      # Link to the underlying rbgccxml node this node is writing code for
      attr_accessor :code

      # List of children nodes
      attr_accessor :nodes

      # List of children nodes that generate code that the entire extension
      # needs to be able to read. Code that fits here includes any auto-generated
      # to_/from_ruby and any Allocation Strategies
      attr_accessor :global_nodes

      # The Rice variable name for this node
      attr_accessor :rice_variable

      # The type of the rice_variable
      attr_accessor :rice_variable_type

      def initialize(code, parent = nil)
        @code = code
        @parent = parent
        @includes = []
        @declarations = []
        @registrations = []
        @nodes = []
        @global_nodes = []
      end

      # Does this builder node have child nodes?
      def has_children?
        @nodes && !@nodes.empty?
      end

      # Trigger the construction of the internal representation of a given node.
      # All nodes must implement this.
      def build
        raise "Nodes must implement #build"
      end

      # After #build has run, this then triggers the actual generation of the C++
      # code and returns the final string.
      # All nodes must implement this.
      def write
        raise "Nodes must implement #write"
      end

      # Once building is done, the resulting node tree needs to be sorted according
      # to subclass / superclass definitions. Like anything with C++, Rice needs to
      # know about base classes before it can build sub classes. We go through
      # each node's children, sorting them according to this.
      def sort
        @nodes.each { |n| n.sort }

        # sort_by lets us build an array of numbers that Ruby then uses
        # to sort the list. Our method here is to simply specify the
        # depth a given class is in a heirarchy, as bigger numbers end
        # up sorted farther down the list
        @nodes =
          @nodes.sort_by do |a|
            a.is_a?(ClassNode) ? superclass_count(a.code) : 0
          end
      end

      # Proxy method for writers
      def qualified_name
        self.code.qualified_name
      end

      protected

      # Count the heirarchy depth of a given class node
      def superclass_count(node)
        count = 0
        n = node
        while n = n.superclass
          count += 1
        end
        count
      end

      # Turn a string that contains a qualified C++ name into a
      # string that works as a C++ variable. e.g.
      #
      #   MyClass::MyEnum => MyClass_MyEnum
      #
      def as_variable(name)
        name.gsub(/::/, "_").gsub(/[<>]/, "_").gsub("*", "_ptr_")
      end

      # Should this node be wrapped as it is or has the user
      # specified something else for this node?
      def do_not_wrap?(node)
        node.ignored? || node.moved? || !node.public?
      end

      # Given a new node, build it and add it to our nodes list
      def add_child(node)
        node.build
        nodes << node
      end

      # Add a node to the "globals" list. See the declaration of global_nodes
      def add_global_child(node)
        node.build
        global_nodes << node
      end

      # Any node can also have a typedef. There are cases where it's
      # much better to use a typedef instead of the original fully qualified
      # name, for example deep template definitions (say, any STL structures).
      # This method will look for the best Typedef to use for this node and will
      #
      # @returns [the name of the node, and the node's fully qualified name] or nil
      def find_typedef
        found = last_found = self.code

        if !self.code._disable_typedef_lookup?
          while found
            last_found = found
            typedef = RbGCCXML::XMLParsing.find(:node_type => "Typedef", :type => found.attributes["id"])

            # Some typedefs have the access attribute, some don't. We want those without the attribute
            # and those with the access="public". For this reason, we can't put :access => "public" in the
            # query above.
            found = (typedef && typedef.public?) ? typedef : nil
          end
        end

        if last_found != self.code
          Logger.debug("Found typedef #{last_found.qualified_name} for #{self.code.qualified_name}")
          [last_found.name, last_found.qualified_name]
        else
          nil
        end
      end

    end

  end
end
