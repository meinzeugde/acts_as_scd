require 'test_helper'

class ActsAsScdTest < ActiveSupport::TestCase

  fixtures :all

  test 'instance-method (association): has_many :countries' do
    #################
    ### FIND ANYTHING
    #################
    # should return an ActiveRecord::Relation
    assert_kind_of ActiveRecord::Relation, Continent.where(:name=>'Europe').first.countries_at_present
    assert_kind_of ActiveRecord::Relation, Continent.where(:name=>'Europe').first.countries_upcoming

    # todo-matteo: write more tests
  end

end
