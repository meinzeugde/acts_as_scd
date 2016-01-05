require 'test_helper'

class CountriesControllerTest < ActionController::TestCase
  fixtures :all

  START_OF_TIME_FORMATTED = '0000-01-01'
  START_OF_TIME = 0
  END_OF_TIME_FORMATTED = '9999-12-31'
  END_OF_TIME = 99999999
  TODAY_FORMATTED = Date.today.strftime('%Y-%m-%d')
  TODAY = Date.today.strftime('%Y%m%d').to_i
  TOMORROW_FORMATTED = Date.tomorrow.strftime('%Y-%m-%d')
  TOMORROW = Date.tomorrow.strftime('%Y%m%d').to_i
  YESTERDAY_FORMATTED = Date.yesterday.strftime('%Y-%m-%d')
  YESTERDAY = Date.yesterday.strftime('%Y%m%d').to_i

  test "should get index at present" do
    get :index
    assert_response :success
    assert_equal "Centuria,Eternal Caledonia,Germany,Scotland,United Kingdom,Volatile Changedonia",
                 json_response.map{|r|r['name']}.sort.uniq.join(',')
  end

  test "should get index at specific date" do
    get :index, {'scd_date' => '1949-01-01'}
    assert_response :success
    assert_equal "Eternal Caledonia,Germany,United Kingdom,Volatile Changedonia",
                 json_response.map{|r|r['name']}.sort.uniq.join(',')
  end

  test "should get germany at present day" do
    get :show, {'id' => 'DEU'}
    assert_response :success
    assert_equal 'Germany', json_response['name']
    assert_equal "DEU", json_response['identity']
    assert_equal 19901003, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']
  end

  test "should get germany at specific date" do
    get :show, {'id' => 'DEU', 'scd_date' => '1949-01-01'}
    assert_response :success
    assert_equal 'Germany', json_response['name']
    assert_equal "DEU", json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal 19491007, json_response['effective_to']
  end

  test "should create a new static country" do
    post :create, {country: {name: 'Static Country', code: 'STC'}}
    assert_response :success
    # return the created period
    assert_equal 'Static Country', json_response['name']
    assert_equal "STC", json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']
  end

  test "should create a new country with start date" do
    post :create, {country: {name: 'Country with Start Date', code: 'CWS', effective_from: '1949-01-01'}}
    assert_response :success
    # return the created period
    assert_equal 'Country with Start Date', json_response['name']
    assert_equal "CWS", json_response['identity']
    assert_equal 19490101, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']
  end

  test "should create a new country with start date and end date" do
    post :create, {country: {name: 'Country with Start Date and End Date', code: 'CSE', effective_from: '1949-01-01', effective_to: '1990-10-03'}}
    assert_response :success
    # return the created period
    assert_equal 'Country with Start Date and End Date', json_response['name']
    assert_equal "CSE", json_response['identity']
    assert_equal 19490101, json_response['effective_from']
    assert_equal 19901003, json_response['effective_to']
  end

  test "should not create a static country which already exists as static country" do
    post :create, {country: {name: 'Eternal Caledonia', code: 'CL'}}
    assert_response :internal_server_error
    assert_equal 'An entry for the identity CL already exists.', json_response['error']
  end

  test "should not create a static country which already exists as limited country" do
    post :create, {country: {name: 'Volatile Changedonia', code: 'CG'}}
    assert_response :internal_server_error
    assert_equal 'An entry for the identity CG already exists.', json_response['error']
  end

  test "should get periods by identity" do
    get :periods_by_identity, {'id' => 'DEU'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal '1949-10-07', json_response[0]['end']
    assert_equal '1949-10-07', json_response[1]['start']
    assert_equal '1990-10-03', json_response[1]['end']
    assert_equal '1990-10-03', json_response[2]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[2]['end']
    assert_nil json_response[3]
  end

  test "should update a static country generating a new period starting today" do
    patch :update, id: 'CL', country: {name: 'New Caledonia', code: 'CL'}
    assert_response :success
    # return the created period
    assert_equal 'New Caledonia', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal TODAY, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal TODAY_FORMATTED, json_response[0]['end']
    assert_equal TODAY_FORMATTED, json_response[1]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[1]['end']
    assert_nil json_response[2]
  end

  test "should update a static country generating a new period starting in the future" do
    patch :update, id: 'CL', country: {name: 'Caledonia of tomorrow', code: 'CL', effective_from: TOMORROW_FORMATTED}
    assert_response :success
    # return the created period
    assert_equal 'Caledonia of tomorrow', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal TOMORROW, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal TOMORROW_FORMATTED, json_response[0]['end']
    assert_equal TOMORROW_FORMATTED, json_response[1]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[1]['end']
    assert_nil json_response[2]
  end

  test "should update a static country generating a new period starting in the past" do
    patch :update, id: 'CL', country: {name: 'Caledonia of yesterday', code: 'CL', effective_from: YESTERDAY_FORMATTED}
    assert_response :success
    # return the created period
    assert_equal 'Caledonia of yesterday', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal YESTERDAY, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal YESTERDAY_FORMATTED, json_response[0]['end']
    assert_equal YESTERDAY_FORMATTED, json_response[1]['start']
    assert_equal END_OF_TIME_FORMATTED, json_response[1]['end']
    assert_nil json_response[2]
  end

  test "should unterminate a static country at today" do
    delete :destroy, id: 'CL'
    assert_response :success
    # return the destroyed period in case of implementing a restore functionality
    assert_equal 'Eternal Caledonia', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal TODAY_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should unterminate a static country in the future" do
    delete :destroy, id: 'CL', country: {effective_from: TOMORROW_FORMATTED}
    assert_response :success
    # return the destroyed period in case of implementing a restore functionality
    assert_equal 'Eternal Caledonia', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal TOMORROW_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

  test "should unterminate a static country in the past" do
    delete :destroy, id: 'CL', country: {effective_from: YESTERDAY_FORMATTED}
    assert_response :success
    # return the destroyed period in case of implementing a restore functionality
    assert_equal 'Eternal Caledonia', json_response['name']
    assert_equal 'CL', json_response['identity']
    assert_equal START_OF_TIME, json_response['effective_from']
    assert_equal END_OF_TIME, json_response['effective_to']

    # check all periods
    get :periods_by_identity, {'id' => 'CL'}
    assert_response :success
    assert_equal START_OF_TIME_FORMATTED, json_response[0]['start']
    assert_equal YESTERDAY_FORMATTED, json_response[0]['end']
    assert_nil json_response[1]
  end

end