require 'test_helper'

class ActsAsScdTest < ActiveSupport::TestCase

  fixtures :all

  test "Models can act as SCD" do
    assert_equal countries(:caledonia), Country.find_by_identity('CL', Date.today)
    assert_equal countries(:caledonia), Country.at_present.where(:identity => 'CL').first
    assert_equal countries(:caledonia), Country.where(:identity => 'CL').at_present.first
    assert_equal Date.new(2014,3,2), countries(:changedonia_first).effective_to_date
    assert_equal Date.new(2014,3,2), countries(:changedonia_second).effective_from_date
    assert_equal countries(:changedonia_third), countries(:changedonia_first).current
    assert_equal countries(:changedonia_third), countries(:changedonia_second).current
    assert_equal countries(:changedonia_second), countries(:changedonia_first).successor
    assert_equal countries(:changedonia_third), countries(:changedonia_second).successor
  end

  test "Method 'current' and 'at_present' is not the same" do
    assert_nil Country.where(:identity => 'CTA').current.first
    assert_equal Country.where(:identity => 'CTA').at_present.first,
                 countries(:centuria)
  end

  test "Identities have iterations" do
    caledonia = countries(:caledonia)
    assert_equal 99999999, caledonia.effective_to
  end

  test "New records have identity automatically assigned and are not time-limited" do
    country = Country.create!(name: 'Testing 1', code: 'T1')
    assert_equal country.identity, 'T1'
    assert_equal ActsAsScd::START_OF_TIME, country.effective_from
    assert_equal ActsAsScd::END_OF_TIME, country.effective_to
  end

  test "New identities are not time-limited" do
    date = Date.new(2014,03,07)
    country = Country.create_identity(name: 'Testing 2', code: 'T2')
    assert_equal country.identity, 'T2'
    assert_equal ActsAsScd::START_OF_TIME, country.effective_from
    assert_equal ActsAsScd::END_OF_TIME, country.effective_to
  end

  test "Effective dates can be accessed as Date values" do
    assert_nil countries(:de1).effective_from_date
    assert_equal Date.new(1949,10,7), countries(:de1).effective_to_date
    assert_equal Date.new(1949,10,7), countries(:de2).effective_from_date
    assert_equal Date.new(1990,10,3), countries(:de2).effective_to_date
    assert_equal Date.new(1990,10,3), countries(:de3).effective_from_date
    assert_nil countries(:de3).effective_to_date
  end

  test "create identities and iterations" do
    t3 = Country.create_identity(name: 'Testing 3', code: 'T3', area: 1000)
    assert_equal t3.identity, 'T3'
    assert_equal ActsAsScd::START_OF_TIME, t3.effective_from
    assert_equal ActsAsScd::END_OF_TIME, t3.effective_to
    assert_equal 'T3', t3.code
    assert_equal 'Testing 3', t3.name
    assert_equal 1000, t3.area

    date1 = Date.new(2014,02,02)
    t3_2 = Country.create_iteration('T3', { area: 2000 }, date1)
    t3.reload
    assert_equal 2000, t3_2.area
    assert_equal t3.code, t3_2.code
    assert_equal t3.name, t3_2.name
    assert_equal ActsAsScd::START_OF_TIME, t3.effective_from
    assert_equal date1, t3.effective_to_date
    assert_equal date1, t3_2.effective_from_date
    assert_equal ActsAsScd::END_OF_TIME, t3_2.effective_to

    date2 = Date.new(2014,03,02)
    t3_3 = Country.create_iteration('T3', { area: 3000 }, date2)
    t3.reload
    t3_2.reload
    assert_equal 3000, t3_3.area
    assert_equal t3.code, t3_3.code
    assert_equal t3.name, t3_3.name
    assert_equal ActsAsScd::START_OF_TIME, t3.effective_from
    assert_equal date1, t3.effective_to_date
    assert_equal date1, t3_2.effective_from_date
    assert_equal date2, t3_2.effective_to_date
    assert_equal date2, t3_3.effective_from_date
    assert_equal ActsAsScd::END_OF_TIME, t3_3.effective_to

    assert_equal t3_3, Country.find_by_identity('T3')

    assert_equal t3_3, t3.current
    assert_equal t3_3, t3.at(date2)
    assert_equal t3_3, t3.at(date2+10)
    assert_equal t3_2, t3.at(date2-1)
    assert_equal t3_2, t3.at(date1)
    assert_equal t3_2, t3.at(date1+10)
    assert_equal t3,   t3.at(date1-1)

    assert_equal t3_3, t3_2.current
    assert_equal t3_3, t3_2.at(date2)
    assert_equal t3_3, t3_2.at(date2+10)
    assert_equal t3_2, t3_2.at(date2-1)

    assert_equal t3, t3.initial
    assert_equal t3, t3_2.initial
    assert_equal t3, t3_3.initial

    assert_equal t3_2, t3.successor
    assert_equal t3_3, t3_2.successor
    assert_nil         t3_3.successor
    assert_equal t3_2, t3_3.antecessor
    assert_equal t3,   t3_2.antecessor
    assert_nil         t3.antecessor
    assert_equal [t3, t3_2], t3_3.antecessors
    assert_equal [t3], t3_2.antecessors
    assert_equal [], t3.antecessors
    assert_equal [t3_2, t3_3], t3.successors
    assert_equal [t3_3], t3_2.successors
    assert_equal [], t3_3.successors
    assert_equal [t3, t3_2, t3_3], t3.history
    assert_equal [t3, t3_2, t3_3], t3_2.history
    assert_equal [t3, t3_2, t3_3], t3_3.history

    assert_equal t3_3, t3.latest
    assert_equal t3_3, t3_2.latest
    assert_equal t3_3, t3_3.latest

    assert_equal t3, t3_3.earliest
    assert_equal t3, t3_2.earliest
    assert_equal t3, t3.earliest

    assert t3.ended?
    assert t3_2.ended?
    assert !t3_3.ended?

    assert !t3.ended_at?(date1-1)
    assert t3.ended_at?(date1)
    assert t3.ended_at?(date1+1)
    assert t3.ended_at?(date2-1)
    assert t3.ended_at?(date2)
    assert t3.ended_at?(date2+1)

    assert !t3_2.ended_at?(date1-1)
    assert !t3_2.ended_at?(date1)
    assert !t3_2.ended_at?(date1+1)
    assert !t3_2.ended_at?(date2-1)
    assert t3_2.ended_at?(date2)
    assert t3_2.ended_at?(date2+1)

    assert !t3_3.ended_at?(date1-1)
    assert !t3_3.ended_at?(date1)
    assert !t3_3.ended_at?(date1+1)
    assert !t3_3.ended_at?(date2-1)
    assert !t3_3.ended_at?(date2)
    assert !t3_3.ended_at?(date2+1)

    assert t3.initial?
    assert !t3_2.initial?
    assert !t3_3.initial?

    assert !t3.current?
    assert !t3_2.current?
    assert t3_3.current?

    assert !t3.past_limited?
    assert t3.future_limited?
    assert t3_2.past_limited?
    assert t3_2.future_limited?
    assert t3_3.past_limited?
    assert !t3_3.future_limited?

    date3 = Date.new(2014,04,02)
    # t3_2.terminate_identity(date3)
    Country.terminate_identity 'T3', date3
    t3.reload
    t3_2.reload
    t3_3.reload
    assert_nil t3.current
    assert_nil t3_2.current
    assert_nil t3_3.current
    assert_nil Country.find_by_identity('T3')

    assert_nil         t3.at(date3+1)
    assert_nil         t3.at(date3)
    assert_equal t3_3, t3.at(date3-1)
    assert_equal t3_3, t3.at(date2)
    assert_equal t3_3, t3.at(date2+10)
    assert_equal t3_2, t3.at(date2-1)
    assert_equal t3_2, t3.at(date1)
    assert_equal t3_2, t3.at(date1+10)
    assert_equal t3,   t3.at(date1-1)

    assert_equal t3_3, t3_2.at(date2)
    assert_equal t3_3, t3_2.at(date2)
    assert_equal t3_2, t3_2.at(date2-1)

    assert_equal t3, t3.initial
    assert_equal t3, t3_2.initial
    assert_equal t3, t3_3.initial

    assert_equal t3_2, t3.successor
    assert_equal t3_3, t3_2.successor
    assert_nil         t3_3.successor
    assert_equal t3_2, t3_3.antecessor
    assert_equal t3,   t3_2.antecessor
    assert_nil         t3.antecessor
    assert_equal [t3, t3_2], t3_3.antecessors
    assert_equal [t3], t3_2.antecessors
    assert_equal [], t3.antecessors
    assert_equal [t3_2, t3_3], t3.successors
    assert_equal [t3_3], t3_2.successors
    assert_equal [], t3_3.successors
    assert_equal [t3, t3_2, t3_3], t3.history
    assert_equal [t3, t3_2, t3_3], t3_2.history
    assert_equal [t3, t3_2, t3_3], t3_3.history

    assert_equal t3_3, t3.latest
    assert_equal t3_3, t3_2.latest
    assert_equal t3_3, t3_3.latest

    assert_equal t3, t3_3.earliest
    assert_equal t3, t3_2.earliest
    assert_equal t3, t3.earliest

    assert t3.ended?
    assert t3_2.ended?
    assert t3_3.ended?

    assert !t3.ended_at?(date1-1)
    assert t3.ended_at?(date1)
    assert t3.ended_at?(date1+1)
    assert t3.ended_at?(date2-1)
    assert t3.ended_at?(date2)
    assert t3.ended_at?(date2+1)

    assert !t3_2.ended_at?(date1-1)
    assert !t3_2.ended_at?(date1)
    assert !t3_2.ended_at?(date1+1)
    assert !t3_2.ended_at?(date2-1)
    assert t3_2.ended_at?(date2)
    assert t3_2.ended_at?(date2+1)

    assert !t3_3.ended_at?(date1-1)
    assert !t3_3.ended_at?(date1)
    assert !t3_3.ended_at?(date1+1)
    assert !t3_3.ended_at?(date2-1)
    assert !t3_3.ended_at?(date2)
    assert !t3_3.ended_at?(date2+1)
    assert !t3_3.ended_at?(date3-1)
    assert  t3_3.ended_at?(date3)
    assert  t3_3.ended_at?(date3+1)

    assert t3.initial?
    assert !t3_2.initial?
    assert !t3_3.initial?

    assert !t3.current?
    assert !t3_2.current?
    assert !t3_3.current?

    assert !t3.past_limited?
    assert t3.future_limited?
    assert t3_2.past_limited?
    assert t3_2.future_limited?
    assert t3_3.past_limited?
    assert t3_3.future_limited?

  end

  test "find_by_identity" do

    de1 = countries(:de1)
    de2 = countries(:de2)
    de3 = countries(:de3)
    ddr = countries(:ddr)
    uk1 = countries(:uk1)
    uk2 = countries(:uk2)
    sco = countries(:scotland)
    cal = countries(:caledonia)

    assert_equal de3, Country.find_by_identity('DEU')
    assert_nil Country.find_by_identity('DDR')
    assert_equal uk2, Country.find_by_identity('GBR')
    assert_equal sco, Country.find_by_identity('SCO')

    assert_equal de3, Country.find_by_identity('DEU', Date.new(3000,1,1))
    assert_equal de3, Country.find_by_identity('DEU', Date.new(2000,1,1))
    assert_equal de3, Country.find_by_identity('DEU', Date.new(1990,10,3))
    assert_equal de2, Country.find_by_identity('DEU', Date.new(1990,10,2))
    assert_equal de2, Country.find_by_identity('DEU', Date.new(1970,1,1))
    assert_equal de2, Country.find_by_identity('DEU', Date.new(1949,10,7))
    assert_equal de1, Country.find_by_identity('DEU', Date.new(1949,10,6))
    assert_equal de1, Country.find_by_identity('DEU', Date.new(1940,1,1))
    assert_equal de1, Country.find_by_identity('DEU', Date.new(1000,1,1))
    assert_equal cal, Country.find_by_identity('CL',  Date.new(3000,1,1))
    assert_equal de3, Country.find_by_identity('DEU', Date.new(2000,1,1))
    assert_equal de3, Country.find_by_identity('DEU', Date.new(1990,10,3))
    assert_equal de2, Country.find_by_identity('DEU', Date.new(1990,10,2))
    assert_equal de2, Country.find_by_identity('DEU', Date.new(1970,1,1))
    assert_equal de2, Country.find_by_identity('DEU', Date.new(1949,10,7))
    assert_equal de1, Country.find_by_identity('DEU', Date.new(1949,10,6))
    assert_equal de1, Country.find_by_identity('DEU', Date.new(1940,1,1))
    assert_equal de1, Country.find_by_identity('DEU', Date.new(1000,1,1))
    assert_nil        Country.find_by_identity('DDR', Date.new(1940,1,1))
    assert_nil        Country.find_by_identity('DDR', Date.new(1949,10,6))
    assert_equal ddr, Country.find_by_identity('DDR', Date.new(1949,10,7))
    assert_equal ddr, Country.find_by_identity('DDR', Date.new(1970,1,1))
    assert_equal ddr, Country.find_by_identity('DDR', Date.new(1990,10,2))
    assert_nil        Country.find_by_identity('DDR', Date.new(1990,10,3))
    assert_nil        Country.find_by_identity('DDR', Date.new(2015,1,1))

  end

  test "identity_exists?" do

    de1 = countries(:de1)
    de2 = countries(:de2)
    de3 = countries(:de3)
    ddr = countries(:ddr)
    uk1 = countries(:uk1)
    uk2 = countries(:uk2)
    sco = countries(:scotland)
    cal = countries(:caledonia)

    assert  Country.identity_exists?('DEU')
    assert  Country.identity_exists?('DDR')
    assert  Country.identity_exists?('GBR')
    assert  Country.identity_exists?('SCO')

    assert  Country.identity_exists?('DEU', Date.new(3000,1,1))
    assert  Country.identity_exists?('DEU', Date.new(2000,1,1))
    assert  Country.identity_exists?('DEU', Date.new(1990,10,3))
    assert  Country.identity_exists?('DEU', Date.new(1990,10,2))
    assert  Country.identity_exists?('DEU', Date.new(1970,1,1))
    assert  Country.identity_exists?('DEU', Date.new(1949,10,7))
    assert  Country.identity_exists?('DEU', Date.new(1949,10,6))
    assert  Country.identity_exists?('DEU', Date.new(1940,1,1))
    assert  Country.identity_exists?('DEU', Date.new(1000,1,1))
    assert  Country.identity_exists?('CL',  Date.new(3000,1,1))
    assert  Country.identity_exists?('DEU', Date.new(2000,1,1))
    assert  Country.identity_exists?('DEU', Date.new(1990,10,3))
    assert  Country.identity_exists?('DEU', Date.new(1990,10,2))
    assert  Country.identity_exists?('DEU', Date.new(1970,1,1))
    assert  Country.identity_exists?('DEU', Date.new(1949,10,7))
    assert  Country.identity_exists?('DEU', Date.new(1949,10,6))
    assert  Country.identity_exists?('DEU', Date.new(1940,1,1))
    assert  Country.identity_exists?('DEU', Date.new(1000,1,1))
    assert !Country.identity_exists?('DDR', Date.new(1940,1,1))
    assert !Country.identity_exists?('DDR', Date.new(1949,10,6))
    assert  Country.identity_exists?('DDR', Date.new(1949,10,7))
    assert  Country.identity_exists?('DDR', Date.new(1970,1,1))
    assert  Country.identity_exists?('DDR', Date.new(1990,10,2))
    assert !Country.identity_exists?('DDR', Date.new(1990,10,3))
    assert !Country.identity_exists?('DDR', Date.new(2015,1,1))

  end

  test "Model query methods" do

    de1 = countries(:de1)
    de2 = countries(:de2)
    de3 = countries(:de3)
    ddr = countries(:ddr)
    uk1 = countries(:uk1)
    uk2 = countries(:uk2)
    sco = countries(:scotland)
    cal = countries(:caledonia)

    assert_equal de3, Country.current.where(identity: 'DEU').first
    assert_nil Country.current.where(identity: 'DDR').first
    assert_equal uk2, Country.current.where(identity: 'GBR').first
    assert_equal sco, Country.current.where(identity: 'SCO').first
    assert_equal 5, Country.current.count

    assert_equal de1, Country.initial.where(identity: 'DEU').first
    assert_nil        Country.initial.where(identity: 'DDR').first
    assert_nil        Country.initial.where(identity: 'SCO').first
    assert_equal uk1, Country.initial.where(identity: 'GBR').first
    assert_equal 4, Country.initial.count

    assert_equal de1, Country.earliest_of('DEU')
    assert_equal uk1, Country.earliest_of('GBR')
    assert_equal ddr, Country.earliest_of('DDR')
    assert_equal sco, Country.earliest_of('SCO')
    assert_equal cal, Country.earliest_of('CL')

    assert_equal de3, Country.at(Date.new(3000,1,1)).where(identity: 'DEU').first
    assert_equal de3, Country.at(Date.new(2000,1,1)).where(identity: 'DEU').first
    assert_equal de3, Country.at(Date.new(1990,10,3)).where(identity: 'DEU').first
    assert_equal de2, Country.at(Date.new(1990,10,2)).where(identity: 'DEU').first
    assert_equal de2, Country.at(Date.new(1970,1,1)).where(identity: 'DEU').first
    assert_equal de2, Country.at(Date.new(1949,10,7)).where(identity: 'DEU').first
    assert_equal de1, Country.at(Date.new(1949,10,6)).where(identity: 'DEU').first
    assert_equal de1, Country.at(Date.new(1940,1,1)).where(identity: 'DEU').first
    assert_equal de1, Country.at(Date.new(1000,1,1)).where(identity: 'DEU').first
    assert_equal cal, Country.at(Date.new(3000,1,1)).where(identity: 'CL').first
    assert_equal de3, Country.at(Date.new(2000,1,1)).where(identity: 'DEU').first
    assert_equal de3, Country.at(Date.new(1990,10,3)).where(identity: 'DEU').first
    assert_equal de2, Country.at(Date.new(1990,10,2)).where(identity: 'DEU').first
    assert_equal de2, Country.at(Date.new(1970,1,1)).where(identity: 'DEU').first
    assert_equal de2, Country.at(Date.new(1949,10,7)).where(identity: 'DEU').first
    assert_equal de1, Country.at(Date.new(1949,10,6)).where(identity: 'DEU').first
    assert_equal de1, Country.at(Date.new(1940,1,1)).where(identity: 'DEU').first
    assert_equal de1, Country.at(Date.new(1000,1,1)).where(identity: 'DEU').first
    assert_nil Country.at(Date.new(1940,1,1)).where(identity: 'DDR').first
    assert_nil Country.at(Date.new(1949,10,6)).where(identity: 'DDR').first
    assert_equal ddr, Country.at(Date.new(1949,10,7)).where(identity: 'DDR').first
    assert_equal ddr, Country.at(Date.new(1970,1,1)).where(identity: 'DDR').first
    assert_equal ddr, Country.at(Date.new(1990,10,2)).where(identity: 'DDR').first
    assert_nil        Country.at(Date.new(1990,10,3)).where(identity: 'DDR').first
    assert_nil        Country.at(Date.new(2015,1,1)).where(identity: 'DDR').first
    assert_equal 4, Country.at(Date.new(1940,1,1)).count
    assert_equal 4, Country.at(Date.new(1949,10,6)).count
    assert_equal 5, Country.at(Date.new(1949,10,7)).count
    assert_equal 5, Country.at(Date.new(1970,1,1)).count
    assert_equal 5, Country.at(Date.new(1990,10,2)).count
    assert_equal 4, Country.at(Date.new(1990,10,3)).count
    assert_equal 4, Country.at(Date.new(2000,1,1)).count
    assert_equal 4, Country.at(Date.new(2000,1,1)).count
    assert_equal 4, Country.at(Date.new(2014,3,1)).count
    assert_equal 4, Country.at(Date.new(2014,3,2)).count
    assert_equal 4, Country.at(Date.new(2014,9,17)).count
    assert_equal 5, Country.at(Date.new(2014,9,18)).count
    assert_equal 5, Country.at(Date.new(2015,1,1)).count

    assert_equal 7, Country.ended.count
    assert_equal ddr, Country.ended.where(identity: 'DDR').first

    assert_equal [de1, de2, de3], Country.all_of('DEU')

    assert_equal false, Country.has_unlimited?('DEU')
    assert_equal true, Country.has_unlimited?('CL')

    # These generate queries that are valid for PostgreSQL but not for SQLite3
    #   (v1, v2) IN SELECT ...
    # assert_equal 1, Country.ended.latest.count
    # assert_equal 1, Country.terminated.count
    # assert_equal 1, Country.superseded.count
  end

  test "Model query methods that return objects" do

    de1 = countries(:de1)
    de2 = countries(:de2)
    de3 = countries(:de3)
    ddr = countries(:ddr)
    uk1 = countries(:uk1)
    uk2 = countries(:uk2)
    sco = countries(:scotland)
    cal = countries(:caledonia)

    assert_equal de3, Country.latest_of('DEU')
    assert_equal ddr, Country.latest_of('DDR')
    assert_equal uk2, Country.latest_of('GBR')
    assert_equal sco, Country.latest_of('SCO')

    assert_equal de1, Country.earliest_of('DEU')
    assert_equal ddr, Country.earliest_of('DDR')
    assert_equal uk1, Country.earliest_of('GBR')
    assert_equal sco, Country.earliest_of('SCO')

    c = Country.scoped

    assert_equal %w(CG CL CTA DDR DEU GBR SCO), Country.ordered_identities
    assert_equal %w(CG CL DEU GBR SCO), Country.current.ordered_identities
    assert_equal %w(CG CL DEU GBR SCO), Country.at(Date.new(2015,1,1)).ordered_identities
    assert_equal %w(CG CL DEU GBR SCO), Country.at(Date.new(2014,9,18)).ordered_identities
    assert_equal %w(CG CL DEU GBR), Country.at(Date.new(2014,9,17)).ordered_identities
    assert_equal %w(CG CL DEU GBR), Country.at(Date.new(2014,3,2)).ordered_identities
    assert_equal %w(CG CL DEU GBR), Country.at(Date.new(2014,3,1)).ordered_identities
    assert_equal %w(CG CL DEU GBR), Country.at(Date.new(1990,10,3)).ordered_identities
    assert_equal %w(CG CL DDR DEU GBR), Country.at(Date.new(1990,10,2)).ordered_identities
    assert_equal %w(CG CL DDR DEU GBR), Country.at(Date.new(1970,1,1)).ordered_identities
    assert_equal %w(CG CL DDR DEU GBR), Country.at(Date.new(1949,10,7)).ordered_identities
    assert_equal %w(CG CL DEU GBR), Country.at(Date.new(1949,10,6)).ordered_identities
    assert_equal %w(CG CL DEU GBR), Country.at(Date.new(1940,1,1)).ordered_identities

    assert_equal %w(CG CL CTA DDR DEU GBR SCO), Country.ordered_identities
    assert_equal %w(CG CL DEU GBR SCO), Country.current.ordered_identities
    assert_equal %w(CG CL DEU GBR SCO), Country.identities_at(Date.new(2015,1,1)).sort
    assert_equal %w(CG CL DEU GBR SCO), Country.identities_at(Date.new(2014,9,18)).sort
    assert_equal %w(CG CL DEU GBR), Country.identities_at(Date.new(2014,9,17)).sort
    assert_equal %w(CG CL DEU GBR), Country.identities_at(Date.new(2014,3,2)).sort
    assert_equal %w(CG CL DEU GBR), Country.identities_at(Date.new(2014,3,1)).sort
    assert_equal %w(CG CL DEU GBR), Country.identities_at(Date.new(1990,10,3)).sort
    assert_equal %w(CG CL DDR DEU GBR), Country.identities_at(Date.new(1990,10,2)).sort
    assert_equal %w(CG CL DDR DEU GBR), Country.identities_at(Date.new(1970,1,1)).sort
    assert_equal %w(CG CL DDR DEU GBR), Country.identities_at(Date.new(1949,10,7)).sort
    assert_equal %w(CG CL DEU GBR), Country.identities_at(Date.new(1949,10,6)).sort
    assert_equal %w(CG CL DEU GBR), Country.identities_at(Date.new(1940,1,1)).sort

    assert_equal %w(CG CL DEU GBR SCO), Country.current_identities.sort

    assert_equal [ActsAsScd::Period[0, 99999999]],
                 Country.where(identity: 'CL').effective_periods
    assert_equal [ActsAsScd::Period[19491007, 19901003]],
                 Country.where(identity: 'DDR').effective_periods
    assert_equal [ActsAsScd::Period[20140918, 99999999]],
                 Country.where(identity: 'SCO').effective_periods
    assert_equal [ActsAsScd::Period[0, 20140918], ActsAsScd::Period[20140918, 99999999]],
                 Country.where(identity: 'GBR').effective_periods
    assert_equal [ActsAsScd::Period[0, 19491007], ActsAsScd::Period[19491007, 19901003], ActsAsScd::Period[19901003, 99999999]],
                 Country.where(identity: 'DEU').effective_periods
    assert_equal [[0,19491007], [0, 20140302], [0, 20140918], [0, 99999999], [19491007, 19901003], [19901003, 99999999],
                  [20140302, 20140507], [20140507, 99999999], [20140918, 99999999], [20151201, 21151201]].map{|p| ActsAsScd::Period[*p]},
                 Country.effective_periods

  end

  test "has_many_iterations_through_identity association" do

    de1 = countries(:de1)
    de2 = countries(:de2)
    de3 = countries(:de3)
    ddr = countries(:ddr)
    uk1 = countries(:uk1)
    uk2 = countries(:uk2)
    sco = countries(:scotland)
    cal = countries(:caledonia)

    # current citites
    assert_equal [:berlin3, :hamburg, :leipzig_3].map{|c| cities(c)},
                 de3.cities.order('code')

    # all iterations
    assert_equal [:berlin1, :berlin2, :berlin3, :hamburg, :leipzig_1, :leipzig_3].map{|c| cities(c)},
                 de3.city_iterations.order('code, effective_from')
    assert_equal [:berlin1, :berlin2, :berlin3, :hamburg, :leipzig_1, :leipzig_3].map{|c| cities(c)},
                 de2.city_iterations.order('code, effective_from')
    assert_equal [:berlin1, :berlin2, :berlin3, :hamburg, :leipzig_1, :leipzig_3].map{|c| cities(c)},
                 de1.city_iterations.order('code, effective_from')
    assert_equal [:e_berlin, :leipzig_2].map{|c| cities(c)},
                 ddr.city_iterations.order('code, effective_from')

    assert_equal [:berlin1, :hamburg, :leipzig_1].map{|c| cities(c)},
                 de3.cities_at(Date.new(1949,10,6)).order('code')
    assert_equal [:berlin2, :hamburg].map{|c| cities(c)},
                 de3.cities_at(Date.new(1949,10,7)).order('code')
    assert_equal [:berlin2, :hamburg].map{|c| cities(c)},
                 de3.cities_at(Date.new(1990,10,2)).order('code')
    assert_equal [:berlin3, :hamburg, :leipzig_3].map{|c| cities(c)},
                 de3.cities_at(Date.new(1990,10,3)).order('code')

    assert_equal %w(BER HAM LEI), de3.city_identities.sort
    assert_equal %w(BER HAM LEI), de3.city_identities_at(Date.new(1949,10,6)).sort
    assert_equal %w(BER HAM), de3.city_identities_at(Date.new(1949,10,7)).sort
    assert_equal %w(BER HAM), de3.city_identities_at(Date.new(1990,10,2)).sort
    assert_equal %w(BER HAM LEI), de3.city_identities_at(Date.new(1990,10,3)).sort

    assert_equal %w(BER HAM LEI), de3.city_current_identities.sort
    assert_equal %w(BER HAM LEI), de2.city_current_identities.sort
    assert_equal %w(BER HAM LEI), de1.city_current_identities.sort

    # current city countries
    assert_equal de3, cities(:hamburg).country
    assert_equal de3, cities(:berlin1).country
    assert_equal de3, cities(:berlin2).country
    assert_equal de3, cities(:berlin3).country
    assert_equal de3, cities(:leipzig_1).country
    assert_equal de3, cities(:leipzig_3).country
    assert_nil        cities(:leipzig_2).country

    assert_equal de1, cities(:hamburg).country_at(Date.new(1949,10,6))
    assert_equal de2, cities(:hamburg).country_at(Date.new(1949,10,7))
    assert_equal de2, cities(:hamburg).country_at(Date.new(1990,10,2))
    assert_equal de3, cities(:hamburg).country_at(Date.new(1990,10,3))

    assert_equal de1, cities(:berlin1).country_at(Date.new(1949,10,6))
    assert_equal de2, cities(:berlin1).country_at(Date.new(1949,10,7))
    assert_equal de2, cities(:berlin1).country_at(Date.new(1990,10,2))
    assert_equal de3, cities(:berlin1).country_at(Date.new(1990,10,3))

    assert_equal de1, cities(:berlin2).country_at(Date.new(1949,10,6))
    assert_equal de2, cities(:berlin2).country_at(Date.new(1949,10,7))
    assert_equal de2, cities(:berlin2).country_at(Date.new(1990,10,2))
    assert_equal de3, cities(:berlin2).country_at(Date.new(1990,10,3))

    assert_equal de1, cities(:berlin3).country_at(Date.new(1949,10,6))
    assert_equal de2, cities(:berlin3).country_at(Date.new(1949,10,7))
    assert_equal de2, cities(:berlin3).country_at(Date.new(1990,10,2))
    assert_equal de3, cities(:berlin3).country_at(Date.new(1990,10,3))

    assert_nil        cities(:e_berlin).country_at(Date.new(1949,10,6))
    assert_equal ddr, cities(:e_berlin).country_at(Date.new(1949,10,7))
    assert_equal ddr, cities(:e_berlin).country_at(Date.new(1990,10,2))
    assert_nil        cities(:e_berlin).country_at(Date.new(1990,10,3))

    assert_equal de1, cities(:leipzig_1).country_at(Date.new(1949,10,6))
    assert_equal de2, cities(:leipzig_1).country_at(Date.new(1949,10,7)) # may cause surprise
    assert_equal de2, cities(:leipzig_1).country_at(Date.new(1990,10,2)) # may cause surprise
    assert_equal de3, cities(:leipzig_1).country_at(Date.new(1990,10,3))

    assert_nil        cities(:leipzig_2).country_at(Date.new(1949,10,6)) # may cause surprise
    assert_equal ddr, cities(:leipzig_2).country_at(Date.new(1949,10,7))
    assert_equal ddr, cities(:leipzig_2).country_at(Date.new(1990,10,2))
    assert_nil        cities(:leipzig_2).country_at(Date.new(1990,10,3)) # may cause surprise

    assert_equal de1, cities(:leipzig_3).country_at(Date.new(1949,10,6))
    assert_equal de2, cities(:leipzig_3).country_at(Date.new(1949,10,7)) # may cause surprise
    assert_equal de2, cities(:leipzig_3).country_at(Date.new(1990,10,2)) # may cause surprise
    assert_equal de3, cities(:leipzig_3).country_at(Date.new(1990,10,3))

    # To avoid surprises, cities iterations should also be selected at the evaluation date:
    date1 = Date.new(1949,10,7)
    date2 = Date.new(1990,10,3)
    assert_equal de1, cities(:leipzig_1).at(date1-1).country_at(date1-1)
    assert_equal ddr, cities(:leipzig_1).at(date1).country_at(date1)
    assert_equal ddr, cities(:leipzig_1).at(date2-1).country_at(date2-1)
    assert_equal de3, cities(:leipzig_1).at(date2).country_at(date2)
    assert_equal de1, cities(:leipzig_2).at(date1-1).country_at(date1-1)
    assert_equal ddr, cities(:leipzig_2).at(date1).country_at(date1)
    assert_equal ddr, cities(:leipzig_2).at(date2-1).country_at(date2-1)
    assert_equal de3, cities(:leipzig_2).at(date2).country_at(date2)
    assert_equal de1, cities(:leipzig_3).at(date1-1).country_at(date1-1)
    assert_equal ddr, cities(:leipzig_3).at(date1).country_at(date1)
    assert_equal ddr, cities(:leipzig_3).at(date2-1).country_at(date2-1)
    assert_equal de3, cities(:leipzig_3).at(date2).country_at(date2)

  end

  test "query methods applied to associations" do
    assert_equal  [:berlin3, :hamburg, :leipzig_3].map{|c| cities(c)},
                  countries(:de3).city_iterations.current.order('code')
    assert_equal  [:berlin1, :hamburg, :leipzig_1].map{|c| cities(c)},
                  countries(:de3).city_iterations.at(Date.new(1949,10,6)).order('code')
    assert_equal  [:berlin2, :hamburg].map{|c| cities(c)},
                  countries(:de3).city_iterations.at(Date.new(1949,10,7)).order('code')
    assert_equal  [:berlin2, :hamburg].map{|c| cities(c)},
                  countries(:de3).city_iterations.at(Date.new(1990,10,2)).order('code')
    assert_equal  [:berlin3, :hamburg, :leipzig_3].map{|c| cities(c)},
                  countries(:de3).city_iterations.at(Date.new(1990,10,3)).order('code')

    assert_equal  %w(BER HAM LEI),
                  countries(:de3).city_iterations.ordered_identities
    assert_equal  %w(BER HAM LEI),
                  countries(:de3).city_iterations.at(Date.new(1949,10,6)).ordered_identities
    assert_equal  %w(BER HAM),
                  countries(:de3).city_iterations.at(Date.new(1949,10,7)).ordered_identities
    assert_equal  %w(BER HAM),
                  countries(:de3).city_iterations.at(Date.new(1990,10,2)).ordered_identities
    assert_equal  %w(BER HAM LEI),
                  countries(:de3).city_iterations.at(Date.new(1990,10,3)).ordered_identities

  end

  test "Periods - Standard methods" do
    germany = Country.where(identity: 'DEU')
    periods = germany.effective_periods

    assert_equal [ActsAsScd::Period[0, 19491007], ActsAsScd::Period[19491007, 19901003], ActsAsScd::Period[19901003, 99999999]],
                 periods
    assert_equal periods,
                 Country.effective_periods(identity: 'DEU')

    assert periods[2].valid?
    assert !periods[2].invalid?
    assert periods[2].limited_start?
    assert !periods[2].unlimited_start?
    assert periods[2].unlimited_end?
    assert !periods[2].limited_end?
    assert periods[2].limited?
    assert !periods[2].unlimited?
    assert periods[2].at_present?
    assert !periods[2].at?(Date.new(1949,10,7))

    assert_equal 19491006,
                 periods[0].reference_date
    assert_equal 19491007,
                 periods[1].reference_date
    assert_equal 19901003,
                 periods[2].reference_date
    assert_equal [19491006,19491007,19901003],
                 germany.reference_dates
  end

  test "Periods - Formatted methods" do
    germany = Country.where(identity: 'DEU')
    periods = germany.effective_periods

    assert_equal [{:start => '0000-01-01', :end => '1949-10-07', :reference => '1949-10-06'},{:start => '1949-10-07', :end => '1990-10-03', :reference => '1949-10-07'},{:start => '1990-10-03', :end => '9999-12-31', :reference => '1990-10-03'}],
                 germany.effective_periods_formatted
    assert_equal germany.effective_periods_formatted,
                 Country.effective_periods_formatted('%Y-%m-%d',identity: 'DEU')

    assert_equal [{:start => '01.01.0000', :end => '07.10.1949', :reference => '06.10.1949'},{:start => '07.10.1949', :end => '03.10.1990', :reference => '07.10.1949'},{:start => '03.10.1990', :end => '31.12.9999', :reference => '03.10.1990'}],
                 germany.effective_periods_formatted('%d.%m.%Y')
    assert_equal germany.effective_periods_formatted('%d.%m.%Y'),
                 Country.effective_periods_formatted('%d.%m.%Y',identity: 'DEU')

    assert_equal ['1949-10-06','1949-10-07','1990-10-03'],
                 germany.reference_dates_formatted
    assert_equal germany.reference_dates_formatted,
                 Country.reference_dates_formatted('%Y-%m-%d',identity: 'DEU')

    assert_equal ['06.10.1949','07.10.1949','03.10.1990'],
                 germany.reference_dates_formatted('%d.%m.%Y')
    assert_equal germany.reference_dates_formatted('%d.%m.%Y'),
                 Country.reference_dates_formatted('%d.%m.%Y',identity: 'DEU')

    assert_equal({:start => '0000-01-01', :end => '1949-10-07', :reference=> '1949-10-06'},
                 periods[0].formatted)
    assert_equal({:start => '01.01.0000', :end => '07.10.1949', :reference=> '06.10.1949'},
                 periods[0].formatted('%d.%m.%Y'))

    assert_equal '1949-10-06',
                 periods[0].reference_date_formatted
    assert_equal '06.10.1949',
                 periods[0].reference_date_formatted('%d.%m.%Y')
  end

  test "Periods - Combined Periods" do
    germany_and_uk = Country.where('identity = ? OR identity = ?','DEU','GBR')

    assert_equal [ActsAsScd::Period[0, 19491007], ActsAsScd::Period[0, 20140918], ActsAsScd::Period[19491007, 19901003], ActsAsScd::Period[19901003, 99999999], ActsAsScd::Period[20140918, 99999999]],
                 germany_and_uk.effective_periods

    assert_equal [ActsAsScd::Period[0, 19491007], ActsAsScd::Period[19491007, 19901003], ActsAsScd::Period[19901003, 20140918], ActsAsScd::Period[20140918, 99999999]],
                 germany_and_uk.combined_periods

    assert_equal [{:start => '0000-01-01', :end => '1949-10-07', :reference => '1949-10-06'},
                  {:start => '1949-10-07', :end => '1990-10-03', :reference => '1949-10-07'},
                  {:start => '1990-10-03', :end => '2014-09-18', :reference => '1990-10-03'},
                  {:start => '2014-09-18', :end => '9999-12-31', :reference => '2014-09-18'},
                 ],
                 germany_and_uk.combined_periods_formatted
    assert_equal germany_and_uk.combined_periods_formatted,
                 Country.combined_periods_formatted('%Y-%m-%d','identity = ? OR identity = ?','DEU','GBR')

    assert_equal [{:start => '01.01.0000', :end => '07.10.1949', :reference => '06.10.1949'},
                  {:start => '07.10.1949', :end => '03.10.1990', :reference => '07.10.1949'},
                  {:start => '03.10.1990', :end => '18.09.2014', :reference => '03.10.1990'},
                  {:start => '18.09.2014', :end => '31.12.9999', :reference => '18.09.2014'}
                 ],
                 germany_and_uk.combined_periods_formatted('%d.%m.%Y')
  end

end
