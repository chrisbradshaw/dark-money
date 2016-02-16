class WelcomeController < ApplicationController
  def index
    render 'index'
  end

  def about
    render 'about'
  end

  def contact
    render 'contact'
  end

  def help
    render 'help'
  end
end
