require 'test_helper'

class ContinentsControllerTest < ActionController::TestCase
  fixtures :all

  ######
  ### INDEX
  ######
  test "should get all continents" do
    get :index
    assert_response :success

    continents = json_response.sort_by{|r|r['name']}
    assert_equal 'Asia,Europe,Imaginareum,North America,South America',
                 continents.map{|r|r['name']}.uniq.join(',')

    #check serialized associations as defined in ContinentSerializer
    europe = continents[1]
    europe_countries_at_present = europe['countries_at_present'].sort_by{|r|r['name']}
    europe_countries_upcoming = europe['countries_upcoming'].sort_by{|r|r['name']}
    assert_equal 'Eternal Caledonia,Germany,Scotland,United Kingdom',
                 europe_countries_at_present.map{|r|r['name']}.uniq.join(',')
    assert_equal '',
                 europe_countries_upcoming.map{|r|r['name']}.uniq.join(',')

    imaginareum = continents[2]
    imaginareum_countries_at_present = imaginareum['countries_at_present'].sort_by{|r|r['name']}
    imaginareum_countries_upcoming = imaginareum['countries_upcoming'].sort_by{|r|r['name']}
    assert_equal 'Centuria,Land formerly founded today,Volatile Changedonia',
                 imaginareum_countries_at_present.map{|r|r['name']}.uniq.join(',')
    assert_equal 'Land formerly founded in the future',
                 imaginareum_countries_upcoming.map{|r|r['name']}.uniq.join(',')

    #check serialized associations as defined in CountrySerializer
    germany = europe_countries_at_present[1]
    germany_cities_at_present = germany['cities_at_present'].sort_by{|r|r['name']}
    germany_cities_upcoming = germany['cities_upcoming'].sort_by{|r|r['name']}
    assert_equal 'Berlin,Hamburg,Leipzig',
                 germany_cities_at_present.map{|r|r['name']}.uniq.join(',')
    assert_equal '',
                 germany_cities_upcoming.map{|r|r['name']}.uniq.join(',')

    land_of_today = imaginareum_countries_at_present[1]
    land_of_today_cities_at_present = land_of_today['cities_at_present'].sort_by{|r|r['name']}
    land_of_today_cities_upcoming = land_of_today['cities_upcoming'].sort_by{|r|r['name']}
    assert_equal 'Present Capital',
                 land_of_today_cities_at_present.map{|r|r['name']}.uniq.join(',')
    assert_equal 'Upcoming Capital',
                 land_of_today_cities_upcoming.map{|r|r['name']}.uniq.join(',')

  end

  ######
  ### SHOW
  ######

  ######
  ### CREATE
  ######

  ######
  ### UPDATE
  ######

  ######
  ### DESTROY
  ######
end