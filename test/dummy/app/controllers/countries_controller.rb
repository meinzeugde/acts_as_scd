###
# refer to the countries_controller_test.rb for further information
#
# this Controller shows a set of all possible and useful resource (CRUD) methods
# note that all methods are used as the bang-version, since the goal is to achieve an api for a clientside-framework
# see http://stackoverflow.com/a/1761180 for infos about Active Record's bang-methods
#
# you're free to use the none-bang versions, which return false instead of an exception if an error occurs
# the bang-free versions are tested in the model tests
###
class CountriesController < ApplicationController
  def index
    begin
      render json: Country.at_present_or!(map_scd_date)
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  def past
    begin
      render json: Country.past!
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  def upcoming
    begin
      render json: Country.upcoming!
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  def show
    begin
      render json: Country.find_by_identity_at_present_or!(params[:id],map_scd_date)
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  # todo-matteo: try to combined with create_iteration
  def create
    begin
      country = Country.create_identity!(map_countries_params,map_countries_effective_from,map_countries_effective_to)

      render :json => country
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  # todo-matteo: try to combined with create
  def create_iteration
    begin
      country = Country.create_iteration!(params[:id],map_countries_params,map_countries_effective_from)

      render :json => country
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  # basically this method could also work by primary_key,
  #   this seems more consistent in terms of handing the identity instead of primary_id
  def update
    begin
      # todo-matteo: check what happens when the identity, effective_from and effective_to is not mapped out of the params
      country = Country.update_iteration!(params[:id],map_countries_params,map_scd_date)

      render :json => country
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  # consider renaming to terminate_identity
  def terminate
    begin
      terminated_country = Country.terminate_iteration!(params[:id],map_scd_date)

      render :json => terminated_country
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  def destroy
    begin
      destroyed_countries = Country.destroy_identity!(params[:id])

      render :json => destroyed_countries
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  def destroy_iteration
    begin
      destroyed_country = Country.destroy_iteration!(params[:id],map_scd_date)

      render :json => destroyed_country
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  # consider as alternative to destroy
  def delete
    begin
      # todo-matteo: implement a method which deletes the whole identity (all records) but leave the associations
      # http://stackoverflow.com/a/22757533

      # deleted_country = Country.delete_identity!(params[:id])

      # render :json => deleted_country
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  def delete_iteration
    begin
      # todo-matteo: implement a method which deletes a period but leave the associations
      # deleted_country = Country.delete_iteration!(params[:id],map_scd_date)

      # render :json => destroyed_country
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  # this will summarize all periods without overlapping
  def combined_periods_by_identity
    begin
      render json: Country.combined_periods_formatted('%Y-%m-%d',{:identity=>params[:id]})
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  # this will return all periods nonetheless of overlapping
  def effective_periods_by_identity
    begin
      render json: Country.effective_periods_formatted('%Y-%m-%d',{:identity=>params[:id]})
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  private
  def map_scd_date
    params[:scd_date].to_date rescue nil
  end

  def map_countries_params
    params.require(:country).permit(:code, :name, :area, :continent_id)
  end

  def map_countries_effective_from
    params[:country][:effective_from].to_date rescue nil
  end

  def map_countries_effective_to
    params[:country][:effective_to].to_date rescue nil
  end
end