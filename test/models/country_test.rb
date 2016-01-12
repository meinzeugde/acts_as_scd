require 'test_helper'

class ActsAsScdTest < ActiveSupport::TestCase

  fixtures :all

  test "find_all_by_identity" do
    # should return an Array
    assert_kind_of Array, Country.find_all_by_identity('DEU')

    # should find all countries of an identity ordered by effective_from
    assert_equal [
                     countries(:de1), # DEU
                     countries(:de2), # DEU
                     countries(:de3)  # DEU
                 ], Country.find_all_by_identity('DEU')

    # should return an empty array
    assert_equal [], Country.find_all_by_identity('XXX')
  end

  test "find_all_by_identity!" do
    # should return an Exception
    assert_raises_with_message ActiveRecord::RecordNotFound, 'Could not find any periods.' do
      Country.find_all_by_identity!('XXX')
    end
  end

  test "at_present" do
    # should return an ActiveRecord::Relation
    assert_kind_of ActiveRecord::Relation, Country.at_present

    # should find the present periods of all countries
    assert_equal [
                     countries(:changedonia_third), # CG
                     countries(:caledonia),         # CL
                     countries(:centuria),          # CTA
                     countries(:de3),               # DEU
                     countries(:uk2),               # GBR
                     countries(:landoftoday),       # LOT
                     countries(:scotland),          # SCO
                 ], Country.at_present.order(:identity).to_a

    # should find the present period of a specific country
    assert_equal countries(:de3), Country.at_present.where(identity: 'DEU').first
    assert_equal countries(:de3), Country.where(identity: 'DEU').at_present.first

    # should return an ActiveRecord::Relation
    assert_kind_of ActiveRecord::Relation, Country.where(identity: 'XXX').at_present
    assert_kind_of ActiveRecord::Relation, Country.at_present.where(identity: 'XXX')
  end

  test "at_present!" do
    # should return an Exception
    assert_raises_with_message ActiveRecord::RecordNotFound, 'Could not find any periods.' do
      Country.where(identity: 'XXX').at_present
    end

    # should return an Exception
    assert_raises_with_message ActiveRecord::RecordNotFound, 'Could not find any periods.' do
      Country.at_present.where(identity: 'XXX')
    end
  end

end
