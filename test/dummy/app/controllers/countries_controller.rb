class CountriesController < ApplicationController
  def index

    begin
      render json: Country.at_present_or!(params[:scd_date])
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  def show
    begin
      render json: Country.find_by_identity_at_present_or!(params[:id],params[:scd_date])
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  def create
    begin
      country = Country.create_identity!(map_countries_params,map_countries_effective_from,map_countries_effective_to)
      render :json => country
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  def update
    begin
      new_iteration = Country.create_iteration(params[:id],map_countries_params,map_countries_effective_from)

      render :json => new_iteration
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  def destroy
    begin
      old_country = Country.find_by_identity_at_present_or!(params[:id],map_countries_effective_from)
      Country.terminate_identity(params[:id],map_countries_effective_from)

      render :json => old_country
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  def periods_by_identity
    begin
      render json: Country.combined_periods_formatted('%Y-%m-%d',{:identity=>params[:id]})
    rescue Exception => e
      render :json => {:error => e.message}, :status => :internal_server_error
    end
  end

  private
  ### private Methoden
  def map_countries_params
    params.require(:country).permit(:code, :name, :area, :commercial_association_id)
  end

  def map_countries_effective_from
    params[:country][:effective_from] rescue nil
  end

  def map_countries_effective_to
    params[:country][:effective_to] rescue nil
  end
end