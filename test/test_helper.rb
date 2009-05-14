$:.unshift(File.dirname(__FILE__) + '/../lib')
RAILS_ROOT = File.dirname(__FILE__)

require 'rubygems'
require 'test/unit'
require 'active_record'
require 'active_record/fixtures'

# uh...?
#require 'active_support/binding_of_caller'

ActiveRecord::Base.configurations['test'] = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'][ENV['DB'] || 'sqlite3'])

require "#{File.dirname(__FILE__)}/../init"
load(File.dirname(__FILE__) + "/schema.rb") if File.exist?(File.dirname(__FILE__) + "/schema.rb")

# ActiveSupport::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
# $LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)

require File.dirname(__FILE__) + '/fixtures/user.rb'
require File.dirname(__FILE__) + '/fixtures/preference.rb'

ActiveSupport::TestCase.class_eval do #:nodoc:
  include ActiveRecord::TestFixtures
  
  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
  self.use_instantiated_fixtures  = true

  def assert_difference(object, method = nil, difference = 1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference, object.send(method), "#{object}##{method}"
  end
  
  def assert_no_difference(object, method, &block)
    assert_difference object, method, 0, &block
  end

end