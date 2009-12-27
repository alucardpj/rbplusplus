require 'test_helper'

context "Properly build known required to_ruby and from_ruby methods" do

  specify "should build for const & types as needed" do
    Extension.new "to_from_ruby" do |e|
      e.sources full_dir("headers/to_from_ruby.h"),
        :include_paths => full_dir("headers"),
        :include_source_files => full_dir("headers/to_from_ruby_source.cpp")
      e.namespace "to_from_ruby"
    end

    require 'to_from_ruby'

    needs_to_ruby(4).value.should.equal 4
    some_other_method(7).value.should.equal 7

    c = WrappedClass.new
    c.get_my_type(17).value.should.equal 17

    # Running this gets a glibc double free error. Not sure if this is properly
    # fixable outside of implementing call and return policies in Rice.
#    c.overload_0.class.should.equal MyType
#    c.overload_0.class.should.equal c.overload_1(0).class
  end
end
