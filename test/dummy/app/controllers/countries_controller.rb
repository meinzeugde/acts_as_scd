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
      render json: Country.at_present_or!(params[:scd_date]).find_by_identity!(params[:id])
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
    params[:country][:effective_from]
  end

  def map_countries_effective_to
    params[:country][:effective_to]
  end
end