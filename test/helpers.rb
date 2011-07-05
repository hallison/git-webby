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
      File.join(FIXTURES, *args)
    end

  end
end

