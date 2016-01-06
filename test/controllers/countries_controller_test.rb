require 'test_helper'

class CountriesControllerTest < ActionController::TestCase
  fixtures :all

  ######
  ### INDEX
  ######
  test "should get all countries today" do
    get :index
    assert_response :success
    assert_equal 'Centuria,Eternal Caledonia,Germany,Land formerly founded today,Scotland,United Kingdom,Volatile Changedonia',
                 json_response.map{|r|r['name']}.sort.uniq.join(',')
  end

  test "should get all countries at specific date in the past" do
    get :index, {'scd_date' => '1949-01-01'}
    assert_response :success
    assert_equal 'Eternal Caledonia,Germany,United Kingdom,Volatile Changedonia',
                 json_response.map{|r|r['name']}.sort.uniq.join(',')
  end

  test "should get all countries at specific date in the future" do
    get :index, {'scd_date' => FUTURE_FORMATTED}
    assert_response :success
    assert_equal 'Centuria,Eternal Caledonia,Germany,Land formerly founded in the future,Land formerly founded today,Scotland,United Kingdom,Volatile Changedonia',
                 json_response.map{|r|r['name']}.sort.uniq.join(',')
  end

  ######
  ### SHOW
  ######
  test "should get a specific country today" do
    get :show, {'id' => 'DEU'}
    assert_response :success
    assert_equal 'Germany', json_response['name']
    assert_equal 'DEU', json_response['identity']
    assert_equal 19901003, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']
  end

  test "should get specific country in the past" do
    get :show, {'id' => 'DEU', 'scd_date' => '1949-01-01'}
    assert_response :success
    assert_equal 'Germany', json_response['name']
    assert_equal 'DEU', json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal 19491007, json_response['effective_to']
  end

  test "should get specific country in the future" do
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

  ######
  ### CREATE
  ######
  test "should create a new static country" do
    post :create, {country: {name: 'Static Country', code: 'STC'}}
    assert_response :success
    # return the created period
    assert_equal 'Static Country', json_response['name']
    assert_equal "STC", json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']
  end

  test "should create a new non-static country with start date" do
    post :create, {country: {name: 'Country with Start Date', code: 'CWS', effective_from: '1949-01-01'}}
    assert_response :success
    # return the created period
    assert_equal 'Country with Start Date', json_response['name']
    assert_equal "CWS", json_response['identity']
    assert_equal 19490101, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']
  end

  test "should create a new non-static country with start date and end date" do
    post :create, {country: {name: 'Country with Start Date and End Date', code: 'CSE', effective_from: '1949-01-01', effective_to: '1990-10-03'}}
    assert_response :success
    # return the created period
    assert_equal 'Country with Start Date and End Date', json_response['name']
    assert_equal "CSE", json_response['identity']
    assert_equal 19490101, json_response['effective_from']
    assert_equal 19901003, json_response['effective_to']
  end

  test "should create a new period for a non-static country which does not interfere with existing period" do

  end

  test "should not create a static country which already exists as static country" do
    post :create, {country: {name: 'Eternal Caledonia', code: 'CL'}}
    assert_response :internal_server_error
    assert_equal 'Validation failed: An entry for the identity CL already exists.', json_response['error']
  end

  test "should not create a static country which already exists as non-static country" do
    post :create, {country: {name: 'Volatile Changedonia', code: 'CG'}}
    assert_response :internal_server_error
    assert_equal 'Validation failed: An entry for the identity CG already exists.', json_response['error']
  end

  test "should not create a new period for a non-static country which interferes with existing period" do

  end

  ######
  ### CREATE_ITERATION
  ######
  test "should split a static country by generating a new period starting today" do
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
    # be careful: this may not be suitable in terms of SCD
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
    # this will split up the present period today
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

  test "should not split period of non-static country at start date" do
    patch :create_iteration, id: 'LOT', country: {name: 'Mayfly Land', effective_from: TODAY_FORMATTED}
    assert_response :internal_server_error
    assert_equal 'Validation failed: Can not split period at start-date.', json_response['error']
  end

  test "should not split period of non-static country at end date" do
    # attention: the end_date is the value of effective_to decreased by 1
    patch :create_iteration, id: 'DDR', country: {name: 'GDR', effective_from: "1990-10-02"}
    assert_response :internal_server_error
    assert_equal 'Validation failed: Can not split period at end-date.', json_response['error']
  end

  test "should not split past period of non-static country" do
    # no test here, just an explanation, that this behaviour is not implemented/intended
  end

  test "should not split future period of non-static country" do
    # no test here, just an explanation, that this behaviour is not implemented/intended
    # use create methods instead
    # the only way to create a future period is by plitting a static country
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
    # be careful: this may not be suitable in terms of SCD
  end

  ######
  ### TERMINATE
  ######
  test "should terminate a static country today" do
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
    # be careful: this may not be suitable in terms of SCD
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
  test "should remove present period of non-static country" do
    # no period splitting!
    # be careful: this may not be suitable in terms of SCD
    next
  end

  test "should remove future period of non-static country" do
    # no period splitting!
    # be careful: this may not be suitable in terms of SCD
  end

  test "should remove past period of non-static country" do
    # no period splitting!
    # be careful: this may not be suitable in terms of SCD
  end

end