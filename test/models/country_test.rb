require 'test_helper'

class ActsAsScdTest < ActiveSupport::TestCase

  fixtures :all

  test "find_all_by_identity" do
    #################
    ### FIND ANYTHING
    #################
    # should return an Array
    assert_kind_of Array, Country.find_all_by_identity('DEU')

    # should find all countries of an identity ordered by effective_from
    assert_equal [
                     countries(:de1), # DEU
                     countries(:de2), # DEU
                     countries(:de3)  # DEU
                 ], Country.find_all_by_identity('DEU')

    # bang-version of method should behave the same
    assert_kind_of Array, Country.find_all_by_identity!('DEU')
    assert_equal Country.find_all_by_identity('DEU'), Country.find_all_by_identity!('DEU')

    #################
    ### FIND NOTHING
    #################
    # should return an empty array
    assert_equal [], Country.find_all_by_identity('XXX')

    # bang-version should return an Exception
    assert_raises_with_message ActiveRecord::RecordNotFound, 'Could not find any periods.' do
      Country.find_all_by_identity!('XXX')
    end
  end

  test "at_present" do
    #################
    ### FIND ANYTHING
    #################
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

    # bang-version of method should behave the same
    assert_kind_of ActiveRecord::Relation, Country.at_present!
    assert_equal Country.at_present.order(:identity).to_a, Country.at_present!.order(:identity).to_a
    assert_equal Country.at_present.where(identity: 'DEU').first, Country.at_present!.where(identity: 'DEU').first
    assert_equal Country.where(identity: 'DEU').at_present.first, Country.where(identity: 'DEU').at_present!.first

    #################
    ### FIND NOTHING
    #################
    # should return an ActiveRecord::Relation
    assert_kind_of ActiveRecord::Relation, Country.where(identity: 'XXX').at_present
    assert_kind_of ActiveRecord::Relation, Country.at_present.where(identity: 'XXX')

    # bang-version should return an Exception
    assert_raises_with_message ActiveRecord::RecordNotFound, 'Could not find any periods.' do
      Country.where(identity: 'XXX').at_present!
    end
    assert_raises_with_message ActiveRecord::RecordNotFound, 'Could not find any periods.' do
      Country.at_present!.where(identity: 'XXX')
    end
  end

  test "after_date" do
    #################
    ### FIND ANYTHING
    #################
    # should return an ActiveRecord::Relation
    assert_kind_of ActiveRecord::Relation, Country.after_date(Date.today)

    # should find the future periods of all countries
    assert_equal [
                     countries(:landin10days), # LOF
                 ], Country.after_date(Date.today).order(:identity).to_a

    # should find the future period of a specific country
    assert_equal countries(:landin10days), Country.after_date(Date.today).where(identity: 'LOF').first
    assert_equal countries(:landin10days), Country.where(identity: 'LOF').after_date(Date.today).first

    #################
    ### FIND NOTHING
    #################
    # should return an ActiveRecord::Relation
    assert_kind_of ActiveRecord::Relation, Country.where(identity: 'DEU').after_date(Date.today)
    assert_kind_of ActiveRecord::Relation, Country.after_date(Date.today).where(identity: 'DEU')
  end

end
