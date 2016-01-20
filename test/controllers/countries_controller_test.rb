require 'test_helper'

class CountriesControllerTest < ActionController::TestCase
  fixtures :all

  ######
  ### INDEX
  ######
  test "should get all countries today" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^=========^======'=====^=o
    # CTA |                            '-----> | [x] Centuria
    # CL  |----------------------------'-------| [x] Eternal Caledonia
    # DDR |           <-------->       '       | [-] East Germany
    # DEU |----------><--------><------'-------| [x] Germany
    # LOF |                            ' <-----| [-] Land formerly founded in the future
    # LOT |                            '-------| [x] Land formerly founded today
    # SCO |                        <---'-------| [x] Scotland
    # GBR |-----------------------><---'-------| [x] United Kingdom
    # CG  |-----------------------><-><'-------| [x] Volatile Changedonia
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)
    get :index
    assert_response :success
    countries = json_response.sort_by{|r|r['name']}
    assert_equal 'CTA,CL,DEU,LOT,SCO,GBR,CG',
                 countries.map{|r|r['identity']}.uniq.join(',')
    assert_equal 'Centuria,Eternal Caledonia,Germany,Land formerly founded today,Scotland,United Kingdom,Volatile Changedonia',
                 countries.map{|r|r['name']}.uniq.join(',')

    #check serialized associations as defined in CountrySerializer
    germany = countries[2]
    germany_cities_at_present = germany['cities_at_present'].sort_by{|r|r['name']}
    germany_cities_upcoming = germany['cities_upcoming'].sort_by{|r|r['name']}
    assert_equal 'Berlin,Hamburg,Leipzig',
                 germany_cities_at_present.map{|r|r['name']}.uniq.join(',')
    assert_equal '',
                 germany_cities_upcoming.map{|r|r['name']}.uniq.join(',')

    land_of_today = countries[3]
    land_of_today_cities_at_present = land_of_today['cities_at_present'].sort_by{|r|r['name']}
    land_of_today_cities_upcoming = land_of_today['cities_upcoming'].sort_by{|r|r['name']}
    assert_equal 'Present Capital',
                 land_of_today_cities_at_present.map{|r|r['name']}.uniq.join(',')
    assert_equal 'Upcoming Capital',
                 land_of_today_cities_upcoming.map{|r|r['name']}.uniq.join(',')
  end

  test "should get all countries at specific date in the past" do
    # SOT          1950     1990   Today  2115   EOT
    #     o==========='=========^======^=====^=o
    # CTA |           '                <-----> | [-] Centuria
    # DDR |           '-------->               | [x] East Germany
    # CL  |-----------'------------------------| [x] Eternal Caledonia
    # DEU |-----------'--------><--------------| [x] Germany
    # LOF |           '                  <-----| [-] Land formerly founded in the future
    # LOT |           '                <-------| [-] Land formerly founded today
    # SCO |           '            <-----------| [-] Scotland
    # GBR |-----------'-----------><-----------| [x] United Kingdom
    # CG  |-----------'-----------><-><--------| [x] Volatile Changedonia
    #     o==========='========================o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)
    get :index, {'scd_date' => '1950-01-01'}
    assert_response :success
    assert_equal 'DDR,CL,DEU,GBR,CG',
                 json_response.sort_by{|r|r['name']}.map{|r|r['identity']}.uniq.join(',')
    assert_equal 'East Germany,Eternal Caledonia,Germany,United Kingdom,Volatile Changedonia',
                 json_response.map{|r|r['name']}.sort.uniq.join(',')
  end

  test "should get all countries at specific date in the future" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^=========^======^='===^=o
    # CTA |                            <-'---> | [x] Centuria
    # DDR |           <-------->         '     | [-] East Germany
    # CL  |------------------------------'-----| [x] Caledonia
    # DEU |----------><--------><--------'-----| [x] Germany
    # LOF |                              '-----| [x] Land formerly founded in the future
    # LOT |                            <-'-----| [x] Land formerly founded today
    # SCO |                        <-----'-----| [x] Scotland
    # GBR |-----------------------><-----'-----| [x] United Kingdom
    # CG  |-----------------------><-><--'-----| [x] Volatile Changedonia
    #     o=============================='=====o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)
    get :index, {'scd_date' => FUTURE_FORMATTED}
    assert_response :success
    assert_equal 'CTA,CL,DEU,LOF,LOT,SCO,GBR,CG',
                 json_response.sort_by{|r|r['name']}.map{|r|r['identity']}.uniq.join(',')
    assert_equal 'Centuria,Eternal Caledonia,Germany,Land formerly founded in the future,Land formerly founded today,Scotland,United Kingdom,Volatile Changedonia',
                 json_response.map{|r|r['name']}.sort.uniq.join(',')
  end

  test "should get all countries terminated in the past" do
    # SOT          1950     1990   Today  2115   EOT
    #     o'==========^=========^====='^=====^=o
    # CTA |'                          '<-----> | [-] Centuria
    # CL  |'--------------------------'--------| [-] Eternal Caledonia
    # DDR |'          <-------->      '        | [x] East Germany
    # DEU |'---------><--------><-----'--------| [x] Germany (Period 1/2)
    # LOF |'                          '  <-----| [-] Land formerly founded in the future
    # LOT |'                          '<-------| [-] Land formerly founded today
    # SCO |'                       <--'--------| [-] Scotland
    # GBR |'----------------------><--'--------| [x] United Kingdom (Period 1)
    # CG  |'----------------------><->'--------| [x] Volatile Changedonia (Period 1/2)
    #     o'=========================='========o
    #
    # (SOT = Start of time / EOT = End of time / ' ' = Selected Timespan)
    get :past
    assert_response :success
    assert_equal 'DDR,DEU,GBR,CG',
                 json_response.sort_by{|r|r['name']}.map{|r|r['identity']}.uniq.join(',')
    assert_equal 'East Germany,Germany,United Kingdom,Volatile Changedonia',
                 json_response.map{|r|r['name']}.sort.uniq.join(',')
  end

  test "should get all countries starting in the future" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^=========^======^'====^'o
    # CTA |                            <'----->'| [-] Centuria
    # CL  |-----------------------------'-----'| [-] Eternal Caledonia
    # DDR |           <-------->        '     '| [-] East Germany
    # DEU |----------><--------><-------'-----'| [-] Germany
    # LOF |                             '<----'| [x] Land formerly founded in the future
    # LOT |                            <'-----'| [-] Land formerly founded today
    # SCO |                        <----'-----'| [-] Scotland
    # GBR |-----------------------><----'-----'| [-] United Kingdom
    # CG  |-----------------------><-><-'-----'| [-] Volatile Changedonia
    #     o============================='====='o
    #
    # (SOT = Start of time / EOT = End of time / ' ' = Selected Timespan)
    get :upcoming
    assert_response :success
    assert_equal 'LOF',
                 json_response.sort_by{|r|r['name']}.map{|r|r['identity']}.uniq.join(',')
    assert_equal 'Land formerly founded in the future',
                 json_response.map{|r|r['name']}.sort.uniq.join(',')
  end

  ######
  ### SHOW
  ######
  test "should get a specific country today" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^=========^======'=====^=o
    # DEU |----------><--------><------'-------| [x] Germany
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)
    get :show, {'id' => 'DEU'}
    assert_response :success
    assert_equal 'Germany', json_response['name']
    assert_equal 'DEU', json_response['identity']
    assert_equal 19901003, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']
  end

  test "should get specific country in the past" do
    # SOT          1950     1990   Today  2115   EOT
    #     o=========='^========^=======^=====^=o
    # DEU |----------'<--------><--------------| [x] Germany
    #     o=========='=========================o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)
    get :show, {'id' => 'DEU', 'scd_date' => '1949-01-01'}
    assert_response :success
    assert_equal 'Germany', json_response['name']
    assert_equal 'DEU', json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal 19491007, json_response['effective_to']
  end

  test "should get specific country in the future" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^='===^=o
    # LOF |                              '-----| [x] Land formerly founded in the future
    #     o=============================='=====o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)
    get :show, {'id' => 'LOF', 'scd_date' => FUTURE_FORMATTED}
    assert_response :success
    assert_equal 'Land formerly founded in the future', json_response['name']
    assert_equal 'LOF', json_response['identity']
    assert_equal FUTURE, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']
  end

  ######
  ### PERIODS
  ######
  test "should get all effective periods of a specific country" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^=========^======^=====^=o
    # DEU |---------->                         |
    # DEU |           <-------->               |
    # DEU |                     <--------------|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)
    get :effective_periods_by_identity, {'id' => 'DEU'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1949-10-07', json_response[0]['end']
    assert_equal '1949-10-07', json_response[1]['start']
    assert_equal '1990-10-03', json_response[1]['end']
    assert_equal '1990-10-03', json_response[2]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[2]['end']
    assert_nil json_response[3]
  end

  test "should get all combined periods of a specific country" do
    # todo-matteo: consider removing this test and the function 'combined_periods_by_identity' at all,
    #   because due to careful validation process it is not allowed to create overlapped periods
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^=========^============^=o
    # DEU |---------->                         |
    # DEU |           <-------->               |
    # DEU |                     <--------------|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)
    get :combined_periods_by_identity, {'id' => 'DEU'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1949-10-07', json_response[0]['end']
    assert_equal '1949-10-07', json_response[1]['start']
    assert_equal '1990-10-03', json_response[1]['end']
    assert_equal '1990-10-03', json_response[2]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[2]['end']
    assert_nil json_response[3]
  end

  ######
  ### CREATE
  ######
  test "should create a new static country" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # STC |++++++++++++++++++++++++++++++++++++|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / + = New Period)
    post :create, {country: {name: 'Static Country', code: 'STC'}}
    assert_response :success
    # return the created period
    assert_equal 'Static Country', json_response['name']
    assert_equal "STC", json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'STC'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should create a new non-static country with start date" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # CWS |           <++++++++++++++++++++++++|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / + = New Period)
    post :create, {country: {name: 'Country with Start Date', code: 'CWS', effective_from: '1949-01-01'}}
    assert_response :success
    # return the created period
    assert_equal 'Country with Start Date', json_response['name']
    assert_equal "CWS", json_response['identity']
    assert_equal 19490101, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CWS'}
    assert_response :success
    assert_equal '1949-01-01', json_response[0]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should create a new non-static country with start date and end date" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # CSE |           <++++++++>               |
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / + = New Period)
    post :create, {country: {name: 'Country with Start Date and End Date', code: 'CSE', effective_from: '1949-01-01', effective_to: '1990-10-03'}}
    assert_response :success
    # return the created period
    assert_equal 'Country with Start Date and End Date', json_response['name']
    assert_equal "CSE", json_response['identity']
    assert_equal 19490101, json_response['effective_from']
    assert_equal 19901003, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CSE'}
    assert_response :success
    assert_equal '1949-01-01', json_response[0]['start']
    assert_equal '1990-10-03', json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should create a new period for a non-static country which does not interfere with existing period" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # DDR1|           <-------->               |
    # DDR2|                     <++++++++++++++|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / + = New Period)
    post :create, {country: {name: 'Germany formerly known as East Germany', code: 'DDR', effective_from: '1990-10-03'}}
    assert_response :success
    # return the created period
    assert_equal 'Germany formerly known as East Germany', json_response['name']
    assert_equal 'DDR', json_response['identity']
    assert_equal 19901003, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DDR'}
    assert_response :success
    assert_equal '1949-10-07', json_response[0]['start']
    assert_equal '1990-10-03', json_response[0]['end']
    assert_equal '1990-10-03', json_response[1]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[1]['end']
    assert_nil json_response[2]
  end

  test "should not create a static country which already exists as static country" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # CL 1|------------------------------------|
    # CL 2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / x = Rejected Period)
    post :create, {country: {name: 'Eternal Caledonia', code: 'CL'}}
    assert_response :internal_server_error
    assert_equal 'Validation failed: The period would interfere with an existing period.', json_response['error']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should not create a static country which already exists as non-static country" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # DDR1|           <-------->               |
    # DDR2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / x = Rejected Period)
    post :create, {country: {name: 'Eternal East Germany', code: 'DDR'}}
    assert_response :internal_server_error
    assert_equal 'Validation failed: The period would interfere with an existing period.', json_response['error']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DDR'}
    assert_response :success
    assert_equal '1949-10-07', json_response[0]['start']
    assert_equal '1990-10-03', json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should not create a new period for a non-static country which interferes with existing period before end" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # DDR1|           <-------->               |
    # DDR2|                 <xxxxxxxxxxxxxxxxxx|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / x = Rejected Period)
    post :create, {country: {name: 'Earlier East Germany', code: 'DDR', effective_from: '1970-10-03'}}
    assert_response :internal_server_error
    assert_equal 'Validation failed: The period would interfere with an existing period.', json_response['error']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DDR'}
    assert_response :success
    assert_equal '1949-10-07', json_response[0]['start']
    assert_equal '1990-10-03', json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should not create a new period for a non-static country which interferes with existing period before start" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # DDR1|           <-------->               |
    # DDR2|xxxxxxxxxxxxxxxx>                   |
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / x = Rejected Period)
    post :create, {country: {name: 'Earliest East Germany', code: 'DDR', effective_to: '1970-10-03'}}
    assert_response :internal_server_error
    assert_equal 'Validation failed: The period would interfere with an existing period.', json_response['error']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DDR'}
    assert_response :success
    assert_equal '1949-10-07', json_response[0]['start']
    assert_equal '1990-10-03', json_response[0]['end']
    assert_nil json_response[1]
  end

  ######
  ### CREATE_ITERATION
  ######
  test "should split a static country by generating a new period starting today" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # CL1 |------------------------------------|
    # CL2 |+++++++++++++++++++++++++++><+++++++|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / + = Splitted Periods)
    post :create_iteration, id: 'CL', country: {name: 'New Caledonia', code: 'CL'}
    assert_response :success
    # return the created period
    assert_equal 'New Caledonia', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal TODAY, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal TODAY_FORMATTED, json_response[0]['end']
    assert_equal TODAY_FORMATTED, json_response[1]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[1]['end']
    assert_nil json_response[2]
  end

  test "should split a static country by generating a new period starting in the future" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # CL1 |------------------------------------|
    # CL2 |++++++++++++++++++++++++++++++><++++|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / + = Splitted Periods)
    post :create_iteration, id: 'CL', country: {name: 'Caledonia of the future', code: 'CL', effective_from: FUTURE_FORMATTED}
    assert_response :success
    # return the created period
    assert_equal 'Caledonia of the future', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal FUTURE, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal FUTURE_FORMATTED, json_response[0]['end']
    assert_equal FUTURE_FORMATTED, json_response[1]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[1]['end']
    assert_nil json_response[2]
  end

  test "should split a static country by generating a new period starting in the past" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # CL1 |------------------------------------|
    # CL2 |++++++++++><++++++++++++++++++++++++|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / + = Splitted Periods)

    # be careful: this may not be suitable in terms of SCD2
    post :create_iteration, id: 'CL', country: {name: 'Caledonia formerly founded in 1950', code: 'CL', effective_from: '1950-10-05'}
    assert_response :success
    # return the created period
    assert_equal 'Caledonia formerly founded in 1950', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal 19501005, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1950-10-05', json_response[0]['end']
    assert_equal '1950-10-05', json_response[1]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[1]['end']
    assert_nil json_response[2]
  end

  test "should split present period of non-static country which starts in the past by generating a new period starting today" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # DEU1|----------><--------><--------------|
    # DEU2|----------><--------><+++++><+++++++|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / + = Splitted Periods)
    patch :create_iteration, id: 'DEU', country: {name: 'Germany Today', effective_from: TODAY_FORMATTED}
    assert_response :success
    # return the updated period
    assert_equal 'Germany Today', json_response['name']
    assert_equal 'DEU', json_response['identity']
    assert_equal TODAY, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DEU'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1949-10-07', json_response[0]['end']
    assert_equal '1949-10-07', json_response[1]['start']
    assert_equal '1990-10-03', json_response[1]['end']
    assert_equal '1990-10-03', json_response[2]['start']
    assert_equal TODAY_FORMATTED, json_response[2]['end']
    assert_equal TODAY_FORMATTED, json_response[3]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[3]['end']
    assert_nil json_response[4]
  end

  test "should split past period of non-static country" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # DEU1|----------><--------><--------------|
    # DEU2|++++><++++><--------><--------------|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / + = Splitted Periods)
    patch :create_iteration, id: 'DEU', country: {name: 'Germany after the golden age', effective_from: '1930-01-01'}
    assert_response :success
    # return the updated period
    assert_equal 'Germany after the golden age', json_response['name']
    assert_equal 'DEU', json_response['identity']
    assert_equal 19300101, json_response['effective_from']
    assert_equal 19491007, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DEU'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1930-01-01', json_response[0]['end']
    assert_equal '1930-01-01', json_response[1]['start']
    assert_equal '1949-10-07', json_response[1]['end']
    assert_equal '1949-10-07', json_response[2]['start']
    assert_equal '1990-10-03', json_response[2]['end']
    assert_equal '1990-10-03', json_response[3]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[3]['end']
    assert_nil json_response[4]
  end

  test "should split future period of non-static country" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # LOF1|                              <-----|
    # LOF2|                              <+><++|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / + = Splitted Periods)
    far_future_formatted = 100.days.since.strftime('%Y-%m-%d')
    far_future = 100.days.since.strftime('%Y%m%d').to_i

    patch :create_iteration, id: 'LOF', country: {name: 'Land of the far future', effective_from: far_future_formatted}
    assert_response :success
    # return the updated period
    assert_equal 'Land of the far future', json_response['name']
    assert_equal 'LOF', json_response['identity']
    assert_equal far_future, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'LOF'}
    assert_response :success
    assert_equal FUTURE_FORMATTED, json_response[0]['start']
    assert_equal far_future_formatted, json_response[0]['end']
    assert_equal far_future_formatted, json_response[1]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[1]['end']
    assert_nil json_response[2]
  end

  test "should not split period of non-static country at start date" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # LOT1|                            <-------|
    # LOT2|                            <x><xxxx|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / x = Rejected Periods)
    patch :create_iteration, id: 'LOT', country: {name: 'Mayfly Land', effective_from: TODAY_FORMATTED}
    assert_response :internal_server_error
    assert_equal 'Validation failed: Can not split period at start-date.', json_response['error']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'LOT'}
    assert_response :success
    assert_equal TODAY_FORMATTED, json_response[0]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should not split period of non-static country at end date" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # DDR1|           <-------->               |
    # DDR2|           <xxxxx><x>               |
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / x = Rejected Periods)

    # attention: the end_date is the value of effective_to decreased by 1
    patch :create_iteration, id: 'DDR', country: {name: 'Land of the fall of the wall', effective_from: "1990-10-02"}
    assert_response :internal_server_error
    assert_equal 'Validation failed: Can not split period at end-date.', json_response['error']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DDR'}
    assert_response :success
    assert_equal "1949-10-07", json_response[0]['start']
    assert_equal "1990-10-03", json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should not split period of non-static country that does not exist" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # DDR1|           <-------->               |
    # DDR2|                            <xxxxxxx|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / x = Rejected Periods)

    # advice: use create method if this case occurs
    patch :create_iteration, id: 'DDR', country: {name: 'DDR', effective_from: TODAY_FORMATTED}
    assert_response :internal_server_error
    assert_equal 'Validation failed: Can not split a period that does not exist.', json_response['error']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DDR'}
    assert_response :success
    assert_equal "1949-10-07", json_response[0]['start']
    assert_equal "1990-10-03", json_response[0]['end']
    assert_nil json_response[1]
  end

  ######
  ### UPDATE
  ######
  test "should update static country without changing period" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # CL  |----------------------------'-------| Eternal Caledonia -> New Eternal Caledonia
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)
    patch :update, id: 'CL', scd_date: Date.today, country: {name: 'New Eternal Caledonia', area: 100}
    assert_response :success
    # return the updated period
    assert_equal 'New Eternal Caledonia', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal 100, json_response['area']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should update present period of non-static country without changing period" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # LOT |                            '-------| Land of today -> Bigger Land of today
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)

    # be careful: this may not be suitable in terms of SCD2
    patch :update, id: 'LOT', scd_date: Date.today, country: {name: 'Bigger Land of today', area: 100}
    assert_response :success
    # return the updated period
    assert_equal 'Bigger Land of today', json_response['name']
    assert_equal 'LOT', json_response['identity']
    assert_equal 100, json_response['area']
    assert_equal TODAY, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'LOT'}
    assert_response :success
    assert_equal TODAY_FORMATTED, json_response[0]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should update future period of non-static country without changing period" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^='===^=o
    # LOF |                              '-----| Land of the Future -> Bigger Land of the future
    #     o=============================='=====o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)

    # be careful: this may not be suitable in terms of SCD2
    patch :update, id: 'LOF', scd_date: FUTURE_FORMATTED, country: {name: 'Bigger Land of the future', area: 100}
    assert_response :success
    # return the updated period
    assert_equal 'Bigger Land of the future', json_response['name']
    assert_equal 'LOF', json_response['identity']
    assert_equal 100, json_response['area']
    assert_equal FUTURE, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'LOF'}
    assert_response :success
    assert_equal FUTURE_FORMATTED, json_response[0]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should update past period of non-static country without changing period" do
    # SOT          1950     1990   Today  2115   EOT
    #     o====='=====^========^=======^=====^=o
    # DEU |-----'----><--------><--------------| Germany -> Earliest known Germany
    #     o====='==============================o
    #
    # (SOT = Start of time / EOT = End of time / + = Splitted Periods)

    # be careful: this may not be suitable in terms of SCD2
    patch :update, id: 'DEU', scd_date: '1930-01-01', country: {name: 'Earliest known Germany'}
    assert_response :success
    # return the updated period
    assert_equal 'Earliest known Germany', json_response['name']
    assert_equal 'DEU', json_response['identity']
    assert_equal 357021, json_response['area']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal 19491007, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DEU'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1949-10-07', json_response[0]['end']
    assert_equal '1949-10-07', json_response[1]['start']
    assert_equal '1990-10-03', json_response[1]['end']
    assert_equal '1990-10-03', json_response[2]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[2]['end']
    assert_nil json_response[3]
  end

  test "should not update period of non-static country at a date on which no period exists" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # LOF |                            ' <-----| Land of the Future
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)

    # be careful: this may not be suitable in terms of SCD2
    patch :update, id: 'LOF', scd_date: Date.today, country: {name: 'Bigger Land of the future', area: 100}
    assert_response :internal_server_error
    assert_equal 'Can not update a period that does not exist.', json_response['error']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'LOF'}
    assert_response :success
    assert_equal FUTURE_FORMATTED, json_response[0]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should not update the period's identity of static country by ignoring the change" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # CL  |----------------------------'-------| Eternal Caledonia
    # ECL |xxxxxxxxxxxxxxxxxxxxxxxxxxxx'xxxxxxx| Eternal Caledonia with identity 'ECL'
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / x = Ignored Period)

    # todo-matteo:  consider implementing update of identity
    #               that would inherit that you have to check if the period does not interfere with an existing period of the new identity
    patch :update, id: 'CL', scd_date: Date.today, country: {name: 'New Eternal Caledonia', identity: 'ECL'}
    assert_response :success
    assert_equal 'CL', json_response['identity']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]

    get :effective_periods_by_identity, {'id' => 'ECL'}
    assert_response :success
    assert_nil json_response[0]
  end

  test "should not update the period's start date of static country by ignoring the change" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # CL1 |----------------------------'-------| Eternal Caledonia
    # CL2 |           <xxxxxxxxxxxxxxxx'xxxxxxx| Eternal Caledonia
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / x = Ignored Period)

    # todo-matteo: consider implementing update of start-date by extending the method 'terminate'
    patch :update, id: 'CL', scd_date: Date.today, country: {name: 'New Eternal Caledonia', effective_from: '1950-01-01'}
    assert_response :success
    assert_equal START_OF_TIME, json_response['effective_from']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should not update the period's end date of static country by ignoring the change" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # CL1 |----------------------------'-------| Eternal Caledonia
    # CL2 |xxxxxxxxxxxxxxxxxxxxxxxxxxxx'       | Eternal Caledonia
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / x = Ignored Period)

    # advice: use the terminate method for this purpose
    patch :update, id: 'CL', scd_date: Date.today, country: {name: 'New Eternal Caledonia', effective_to: '1950-01-01'}
    assert_response :success
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  ######
  ### TERMINATE
  ######
  test "should terminate static country at the end of today" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # CL1 |----------------------------'-------|
    # CL2 |++++++++++++++++++++++++++++'       |
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date / + = Terminated Period)
    delete :terminate, id: 'CL'
    assert_response :success

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal TODAY_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should terminate static country at the end in the future" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^='===^=o
    # CL1 |------------------------------'-----|
    # CL2 |++++++++++++++++++++++++++++++'     |
    #     o=============================='=====o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date / + = Terminated Period)
    delete :terminate, id: 'CL', scd_date: FUTURE_FORMATTED
    assert_response :success

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal FUTURE_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should terminate static country at the end in the past" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^===='===^=======^=====^=o
    # CL1 |----------------'-------------------|
    # CL2 |++++++++++++++++'                   |
    #     o================'===================o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date / + = Terminated Period)

    # be careful: this may not be suitable in terms of SCD2
    delete :terminate, id: 'CL', scd_date: '1965-01-01'
    assert_response :success

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1965-01-01', json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should terminate present period of non-static country at the end today" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # DEU1|----------><--------><------'-------|
    # DEU2|----------><--------><++++++'       |
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date / + = Terminated Period)
    delete :terminate, id: 'DEU', scd_date: TODAY_FORMATTED
    assert_response :success

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DEU'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1949-10-07', json_response[0]['end']
    assert_equal '1949-10-07', json_response[1]['start']
    assert_equal '1990-10-03', json_response[1]['end']
    assert_equal '1990-10-03', json_response[2]['start']
    assert_equal TODAY_FORMATTED, json_response[2]['end']
    assert_nil json_response[3]
  end

  test "should terminate future period of non-static country at the end of a specific date" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^==='=^=o
    # LOF1|                              <-'---|
    # LOF2|                              <+'   |
    #     o================================'===o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date / + = Terminated Period)
    far_future_formatted = 100.days.since.strftime('%Y-%m-%d')
    far_future = 100.days.since.strftime('%Y%m%d').to_i

    delete :terminate, id: 'LOF', scd_date: far_future_formatted
    assert_response :success

    # check all periods
    get :effective_periods_by_identity, {'id' => 'LOF'}
    assert_response :success
    assert_equal FUTURE_FORMATTED, json_response[0]['start']
    assert_equal far_future_formatted, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should terminate past period of non-static country at the end of a specific date" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=============^=o
    # DEU1|----------><--------><--------------|
    # DEU2|----------><+++>     <--------------|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date / + = Terminated Period)

    # be careful: this may not be suitable in terms of SCD2
    delete :terminate, id: 'DEU', scd_date: '1970-01-01'
    assert_response :success

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DEU'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1949-10-07', json_response[0]['end']
    assert_equal '1949-10-07', json_response[1]['start']
    assert_equal '1970-01-01', json_response[1]['end']
    assert_equal '1990-10-03', json_response[2]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[2]['end']
    assert_nil json_response[3]
  end

  test "should not terminate period of non-static country at start date" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # LOT1|                            '-------|
    # LOT2|                            'x>     |
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date / x = Rejected Period)
    delete :terminate, id: 'LOT', scd_date: TODAY_FORMATTED
    assert_response :internal_server_error
    assert_equal 'Validation failed: Can not terminate period at start-date.', json_response['error']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'LOT'}
    assert_response :success
    assert_equal TODAY_FORMATTED, json_response[0]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should not terminate period of non-static country at end date" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========'=======^=====^=o
    # DDR1|           <--------'               |
    # DDR2|           <xxxxxxxx'               |
    #     o===================='===============o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date / x = Rejected Periods)

    # attention: the end_date is the value of effective_to decreased by 1
    delete :terminate, id: 'DDR', scd_date: '1990-10-02'
    assert_response :internal_server_error
    assert_equal 'Validation failed: Can not terminate period at end-date.', json_response['error']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DDR'}
    assert_response :success
    assert_equal "1949-10-07", json_response[0]['start']
    assert_equal "1990-10-03", json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should not terminate period of non-static country at a specific date on which no period exists" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # DDR |           <-------->       '       |
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date / x = Rejected Periods)
    delete :terminate, id: 'DDR', scd_date: TODAY_FORMATTED
    assert_response :internal_server_error
    assert_equal 'Can not terminate a period that does not exist.', json_response['error']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DDR'}
    assert_response :success
    assert_equal "1949-10-07", json_response[0]['start']
    assert_equal "1990-10-03", json_response[0]['end']
    assert_nil json_response[1]
  end

  ######
  ### DESTROY ITERATION
  ######
  test "should remove static country" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # CL  |----------------------------'-------| Eternal Caledonia
    #     |                            '       | [Identity Removed]
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time /  ' = Selected Date)

    # be careful: this may not be suitable in terms of SCD2
    delete :destroy_iteration, id: 'CL'
    assert_response :success
    # returns the destroyed period
    assert_equal 'CL', json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_nil json_response[0]
  end

  test "should remove present period of non-static country" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # DEU1|----------><--------><--------------| Germany
    # DEU2|----------><-------->               | Germany
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time /  ' = Selected Date)

    # be careful: this may not be suitable in terms of SCD2
    delete :destroy_iteration, id: 'DEU'
    assert_response :success
    # returns the destroyed period
    assert_equal 'DEU', json_response['identity']
    assert_equal 19901003, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DEU'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1949-10-07', json_response[0]['end']
    assert_equal '1949-10-07', json_response[1]['start']
    assert_equal '1990-10-03', json_response[1]['end']
    assert_nil json_response[2]
  end

  test "should remove future period of non-static country" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # LOF |                            ' <-----| Land of the Future
    #     |                                    | [Identity Removed]
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)
    delete :destroy_iteration, id: 'LOF', scd_date: FUTURE_FORMATTED
    assert_response :success
    # returns the destroyed period
    assert_equal 'LOF', json_response['identity']
    assert_equal FUTURE, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'LOF'}
    assert_response :success
    assert_nil json_response[0]
  end

  test "should remove past period of non-static country" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^==='====^=======^=====^=o
    # DEU1|----------><---'----><--------------| Germany
    # DEU2|---------->    '     <--------------| Germany
    #     o==============='====================o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)

    # be careful: this may not be suitable in terms of SCD2
    delete :destroy_iteration, id: 'DEU', scd_date: '1970-01-01'
    assert_response :success
    # returns the destroyed period
    assert_equal 'DEU', json_response['identity']
    assert_equal 19491007, json_response['effective_from']
    assert_equal 19901003, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DEU'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1949-10-07', json_response[0]['end']
    assert_equal '1990-10-03', json_response[1]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[1]['end']
    assert_nil json_response[2]
  end

  test "should not remove period of non-static country that does not exist" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^======='=====^=o
    # DDR1|           <-------->       '       |
    # DDR2|           <-------->       '       |
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)

    delete :destroy_iteration, id: 'DDR', scd_date: TODAY_FORMATTED
    assert_response :internal_server_error
    assert_equal 'Can not delete a period that does not exist (nor any existing associations).', json_response['error']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DDR'}
    assert_response :success
    assert_equal "1949-10-07", json_response[0]['start']
    assert_equal "1990-10-03", json_response[0]['end']
    assert_nil json_response[1]
  end

  ######
  ### DESTROY IDENTITY
  ######
  test "should completely remove all periods of an identity" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^=========^======'=====^=o
    # DEU1|----------><--------><------'-------|
    # DEU2|                                    |
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time)

    # be careful: this may not be suitable in terms of SCD2
    delete :destroy, id: 'DEU'
    assert_response :success
    # returns the destroyed periods
    assert_equal 3, json_response.size

    # check all periods
    get :effective_periods_by_identity, {'id' => 'DEU'}
    assert_response :success
    assert_nil json_response[0]
  end

  test "should not remove identity that does not exist" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^=========^======'=====^=o
    # XXX |                                    |
    #     o============================'=======o
    #
    # (SOT = Start of time / EOT = End of time)
    delete :destroy, id: 'XXX'
    assert_response :internal_server_error
    assert_equal 'Can not delete an identity that does not exist (nor any existing associations).', json_response['error']
  end
end