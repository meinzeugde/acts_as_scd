###
# refer to the continents_controller_test.rb for further information
#
# this Controller shows a set of all possible and useful resource (CRUD) methods
# note that all methods are used as the bang-version, since the goal is to achieve an api for a clientside-framework
# see http://stackoverflow.com/a/1761180 for infos about Active Record's bang-methods
#
# you're free to use the none-bang versions, which return false instead of an exception if an error occurs
# the bang-free versions are tested in the model tests
###
class ContinentsController < ApplicationController
  def index
    begin
      render json: Continent.all
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end
end