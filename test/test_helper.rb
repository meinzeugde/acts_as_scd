# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require 'active_record/fixtures'
require "active_model_serializers"

ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: [:json]
end

# Disable root element in JSON by default.
ActiveSupport.on_load(:active_record) do
  self.include_root_in_json = false
end

ActiveModel::Serializer.root = false
ActiveModel::ArraySerializer.root = false

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
end

@config = YAML.load_file(File.join(Dir.pwd, "test", "dummy", "config", "database.yml"))['test']

case @config['adapter']
  when 'mysql2'
    ActiveRecord::Base.establish_connection(adapter: @config['adapter'],
                                            :host     => @config['host'],
                                            :username => @config['username'],
                                            :password => @config['password'],
                                            :database => @config['database'])
  when 'sqlite3'
    ActiveRecord::Base.establish_connection(adapter: @config['adapter'],
                                            database: ":memory:")
  else
    raise NotImplementedError, "Unknown (or not yet implemented) adapter type '#{@config['adapter']}'"
end

ActiveRecord::Schema.verbose = true

# Tests data model:
# We'll have two models which represent geographical entities and are subject
# to changes over time such as modified geographical limits, entities may
# disappear or new ones come into existence (as in countries that split, etc.).
# We'll assume to such levels of geographical entities, Country and City for
# which we want to keep the historical state at any time. We'll use a simple
# 'area' field to stand for the various spatial or otherwise properties that
# would typically change between revisions.
ActiveRecord::Schema.define do

  create_table :continents, :force => true do |t|
    t.string  :name
  end

  create_table :countries, :force => true do |t|
    t.string  :code, limit: 3
    t.string  :identity, limit: 3
    t.integer :effective_from, default: 0
    t.integer :effective_to, default: 99999999
    t.string  :name
    t.float   :area
    t.integer :continent_id
  end

  add_index :countries, :identity
  add_index :countries, :effective_from
  add_index :countries, :effective_to
  add_index :countries, [:effective_from, :effective_to]

  create_table :cities, :force => true do |t|
    t.string  :code, limit: 5
    t.string  :identity, limit: 5
    t.integer :effective_from, default: 0
    t.integer :effective_to, default: 99999999
    t.string  :name
    t.float   :area
    t.string  :country_identity, limit: 3
  end

  add_index :cities, :identity
  add_index :cities, :effective_from
  add_index :cities, :effective_to
  add_index :cities, [:effective_from, :effective_to]

  create_table :commercial_delegates, :force => true do |t|
    t.string   :name
    t.string   :country_identity, limit: 3
  end

end

START_OF_TIME_FORMATTED = '0000-01-01'
START_OF_TIME = 0
END_OF_TIME_FORMATTED = '9999-12-31'
END_OF_TIME = 99999999
TODAY_FORMATTED = Date.today.strftime('%Y-%m-%d')
TODAY = Date.today.strftime('%Y%m%d').to_i
FUTURE_FORMATTED = 10.days.since.strftime('%Y-%m-%d')
FUTURE = 10.days.since.strftime('%Y%m%d').to_i

class ActiveSupport::TestCase
  def assert_raises_with_message(exception, msg, &block)
    block.call
  rescue exception => e
    assert_equal msg, e.message
  end
end

class ActionController::TestCase
  def json_response
    ActiveSupport::JSON.decode @response.body
  end
end