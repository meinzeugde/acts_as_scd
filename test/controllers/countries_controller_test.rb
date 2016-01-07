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
    # CL  |----------------------------'-------| [x] Caledonia
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
    assert_equal 'CTA,CL,DEU,LOT,SCO,GBR,CG',
                 json_response.sort_by{|r|r['name']}.map{|r|r['identity']}.uniq.join(',')
    assert_equal 'Centuria,Eternal Caledonia,Germany,Land formerly founded today,Scotland,United Kingdom,Volatile Changedonia',
                 json_response.map{|r|r['name']}.sort.uniq.join(',')
  end

  test "should get all countries at specific date in the past" do
    # SOT          1950     1990   Today  2115   EOT
    #     o=========='^=========^======^=====^=o
    # CTA |          '                 <-----> | [-] Centuria
    # CL  |----------'-------------------------| [x] Caledonia
    # DEU |----------'<--------><--------------| [x] Germany
    # LOF |          '                   <-----| [-] Land formerly founded in the future
    # LOT |          '                 <-------| [-] Land formerly founded today
    # SCO |          '             <-----------| [-] Scotland
    # GBR |----------'------------><-----------| [x] United Kingdom
    # CG  |----------'------------><-><--------| [x] Volatile Changedonia
    #     o=========='=========================o
    #
    # (SOT = Start of time / EOT = End of time / ' = Selected Date)
    get :index, {'scd_date' => '1949-01-01'}
    assert_response :success
    assert_equal 'CL,DEU,GBR,CG',
                 json_response.sort_by{|r|r['name']}.map{|r|r['identity']}.uniq.join(',')
    assert_equal 'Eternal Caledonia,Germany,United Kingdom,Volatile Changedonia',
                 json_response.map{|r|r['name']}.sort.uniq.join(',')
  end

  test "should get all countries at specific date in the future" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^=========^======^='===^=o
    # CTA |                            <-'---> | [x] Centuria
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
    #     o=========='^========^=======^=====^=o
    # LOF |                              '-----| [x] Land formerly founded in the future
    #     o=========='=========================o
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
    # todo-matteo: show the difference between effective and combined periods
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
    assert_equal 'Validation failed: An entry for the identity CL already exists.', json_response['error']
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
    assert_equal 'Validation failed: An entry for the identity DDR already exists.', json_response['error']
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
    assert_equal 'Validation failed: The period since 1970-10-03 for the identity DDR would overlap an existing period.', json_response['error']
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
    assert_equal 'Validation failed: The period to 1970-10-03 for the identity DDR would overlap an existing period.', json_response['error']
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
  end

  test "should split future period of non-static country" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # LOF1|                              <-----|
    # LOF2|                              <-><--|
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time / + = Splitted Periods)
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
    patch :create_iteration, id: 'DDR', country: {name: 'DDR', effective_from: "1990-10-02"}
    assert_response :internal_server_error
    assert_equal 'Validation failed: Can not split period at end-date.', json_response['error']
  end

  ######
  ### UPDATE
  ######
  test "should update static country" do

  end

  test "should update present period of non-static country" do
    # this will update the present period directly
    # no period splitting
    patch :update, id: 'LOT', scd_date: Date.today, country: {name: 'Land of today', area: 100}
    assert_response :success
    # return the updated period
    assert_equal 'Land of today', json_response['name']
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

  test "should update future period of non-static country" do
    # this will update the future period directly
    # no period splitting
    # the only way to create a future period is by plitting a static country

  end

  test "should update past period of non-static country" do
    # this will update the past period directly
    # no period splitting
    # be careful: this may not be suitable in terms of SCD2
  end

  ######
  ### TERMINATE
  ######
  test "should terminate a static country today" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # CL1 |------------------------------------|
    # CL2 |---------------------------->       |
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time)
    delete :terminate, id: 'CL'
    assert_response :success
    # return the destroyed period in case of implementing a restore functionality
    assert_equal 'Eternal Caledonia', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal TODAY_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should terminate a static country in the future" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # CL1 |------------------------------------|
    # CL2 |------------------------------>     |
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time)
    delete :terminate, id: 'CL', country: {effective_from: FUTURE_FORMATTED}
    assert_response :success
    # return the destroyed period in case of implementing a restore functionality
    assert_equal 'Eternal Caledonia', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal FUTURE_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should terminate a static country in the past" do
    # SOT          1950     1990   Today  2115   EOT
    #     o===========^========^=======^=====^=o
    # CL1 |------------------------------------|
    # CL2 |---------------->                   |
    #     o====================================o
    #
    # (SOT = Start of time / EOT = End of time)
    # be careful: this may not be suitable in terms of SCD2
    delete :terminate, id: 'CL', country: {effective_from: '1965-01-01'}
    assert_response :success
    # return the destroyed period in case of implementing a restore functionality
    assert_equal 'Eternal Caledonia', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :effective_periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1965-01-01', json_response[0]['end']
    assert_nil json_response[1]
  end

  ######
  ### DESTROY
  ######
  test "should remove static country" do
    # no period splitting!
    # be careful: this may not be suitable in terms of SCD2
  end

  test "should remove present period of non-static country" do
    # no period splitting!
    # be careful: this may not be suitable in terms of SCD2
  end

  test "should remove future period of non-static country" do
    # no period splitting!
    # be careful: this may not be suitable in terms of SCD2
  end

  test "should remove past period of non-static country" do
    # no period splitting!
    # be careful: this may not be suitable in terms of SCD2
  end

end