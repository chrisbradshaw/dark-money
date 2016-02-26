class DataController < ApplicationController
  YEARS = %w(2004 2006 2008 2010 2012 2014 2016).freeze

  def index
    render :json => scraper_data
  end

  private
  def scraper_data
    #begin
    #  "Scraper::#{params[:data_type].camelize}".constantize.new
    #rescue NameError
    #  "data type not found"
    #end
   case params[:data_type]
    when 'open_secrets_donor'
      YEARS.inject([]) do |overall_data, year| 
        overall_data << Scraper::OpenSecrets.new(year).as_json
      end.flatten
    else
      raise "Data Type Required"
    end

  end
end
