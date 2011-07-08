# This code extracted from book "Ruby Best Practices" and the code be found
# in http://github.com/sandal/rbp/blob/master/testing/test_unit_extensions.rb

FIXTURES  = File.expand_path(File.join(File.dirname(__FILE__), "fixtures")) unless defined? FIXTURES

module Test::Unit
  class TestCase
    def self.should(description, &block)
      test_name = "test_#{description.gsub(/\s+/,'_')}".downcase.to_sym
      defined = instance_method(test_name) rescue false
      raise "#{test_name} is already defined in #{self}" if defined
      if block_given?
        define_method(test_name, &block)
      else
        define_method(test_name) do
          flunk "No implementation provided for #{description}"
        end
      end
    end

    def fixtures(*args)
      File.join(FIXTURES, *(args.map(&:to_s)))
    end

    def debugger
    end unless defined? debugger

  end

  module Assertions

    def assert_hash_equal(expected, actual, message = nil)
      messages = {}
      expected.keys.each do |key|
        equal = actual[key] == expected[key]
        messages[key] = build_message(message, "#{expected[key]} expected but was <?>", actual[key])
        assert_block(messages[key]) { expected[key] == actual[key] }
      end
    end
  end

end

class MockProcess

  def initialize
    @counter = 0
  end

  def write(data)
  end

  def read(data)
  end

  def eof?
    @counter += 1
    @counter > 1 ? true : false
  end

end

class IO
  def self.popen(*args)
    MockProcess.new
  end
end
