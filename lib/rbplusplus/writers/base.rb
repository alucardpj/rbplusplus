module RbPlusPlus
  module Writer

    # Base class for all source code writers
    class Base

      attr_reader :builder, :working_dir

      # Writers all take a builder from which to write out 
      # the source code
      def initialize(builder, working_dir)
        @builder = builder
        @working_dir = working_dir
      end

      # Write out the code 
      def write
        raise "Writers must implement #write"
      end

    end

  end
end
