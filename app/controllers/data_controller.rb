require_relative '../../lib/scraper'


class DataController < ApplicationController
  def index
    render :json => scraper_class.new.as_json
  end

  private
  def scraper_class
    #begin
    #  "Scraper::#{params[:data_type].camelize}".constantize.new
    #rescue NameError
    #  "data type not found"
    #end
   case params[:data_type]
    when 'open_secrets_donor'
      ::OpenSecrets
    else
      raise "Data Type Required"
    end

  end
end
