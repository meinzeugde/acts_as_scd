require 'test_helper'

class ActsAsScdTest < ActiveSupport::TestCase

  fixtures :all

  test "class-method: find_all_by_identity" do
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

  test "class-method: at_present" do
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

  test "class-method: before_date" do
    #################
    ### FIND ANYTHING
    #################
    # should return an ActiveRecord::Relation
    assert_kind_of ActiveRecord::Relation, Country.before_date(Date.today)

    # should find the past periods of all countries
    assert_equal [
                     countries(:de1),                 # DEU
                     countries(:changedonia_first),   # CG
                     countries(:uk1),                 # GBR
                     countries(:ddr),                 # DDR
                     countries(:de2),                 # DEU
                     countries(:changedonia_second),  # CG
                 ], Country.before_date(Date.today).order(:effective_from).to_a

    # should find the past period of a specific country
    assert_equal countries(:uk1), Country.before_date(Date.today).where(identity: 'GBR').first
    assert_equal countries(:uk1), Country.where(identity: 'GBR').before_date(Date.today).first

    #################
    ### FIND NOTHING
    #################
    # should return an ActiveRecord::Relation
    assert_kind_of ActiveRecord::Relation, Country.where(identity: 'SCO').before_date(Date.today)
    assert_kind_of ActiveRecord::Relation, Country.before_date(Date.today).where(identity: 'SCO')
  end

  test "class-method: after_date" do
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

  test 'instance-method (association): has_many :cities' do
    #################
    ### FIND ANYTHING
    #################
    # should return an ActiveRecord::Relation
    assert_kind_of ActiveRecord::Relation, Country.where(:identity=>'DEU').first.cities_at_present
    assert_kind_of ActiveRecord::Relation, Country.where(:identity=>'DEU').first.cities_upcoming

    # todo-matteo: write more tests
  end


end
