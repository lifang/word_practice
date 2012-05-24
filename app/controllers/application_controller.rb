#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  include Constant
  include ApplicationHelper
  

  def check_is_today
    redirect_to "/" if cookies[:user_id].nil?
  end
end
