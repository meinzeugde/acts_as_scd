require 'test_helper'

class CountriesControllerTest < ActionController::TestCase
  fixtures :all

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
    assert_equal "DEU", json_response['identity']
    assert_equal 19901003, json_response['effective_from']
    assert_equal 99999999, json_response['effective_to']
  end

  test "should get germany at specific date" do
    get :show, {'id' => 'DEU', 'scd_date' => '1949-01-01'}
    assert_response :success
    assert_equal "DEU", json_response['identity']
    assert_equal 0, json_response['effective_from']
    assert_equal 19491007, json_response['effective_to']
  end

  test "should create a new static country" do
    post :create, {country: {name: 'Static Country', code: 'STC'}}
    assert_response :success
    assert_equal "STC", json_response['identity']
    assert_equal 0, json_response['effective_from']
    assert_equal 99999999, json_response['effective_to']
  end

end