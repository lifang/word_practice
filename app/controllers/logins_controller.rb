#encoding: utf-8
class LoginsController < ApplicationController
  include LoginsHelper

  def request_qq_web
    redirect_to "#{LoginsHelper::REQUEST_URL_QQ}?#{LoginsHelper::REQUEST_ACCESS_TOKEN.map{|k,v|"#{k}=#{v}"}.join("&")}"
  end

  def respond_qq
    
  end

  def manage_qq_web
    begin
      meters=params[:access_token].split("&")
      access_token=meters[0].split("=")[1]
      expires_in=meters[1].split("=")[1].to_i
      openid=params[:open_id]
      @user= User.find_by_open_id(openid)
      if @user.nil?
        user_url="https://graph.qq.com"
        user_route="/user/get_user_info?access_token=#{access_token}&oauth_consumer_key=#{Oauth2Helper::APPID}&openid=#{openid}"
        user_info=create_get_http(user_url,user_route)
        user_info["nickname"]="qq用户" if user_info["nickname"].nil?||user_info["nickname"]==""
        @user=User.create(:code_type=>'qq',:name=>user_info["nickname"], :username=>user_info["nickname"],
          :open_id=>openid , :access_token=>access_token, :end_time=>Time.now+expires_in.seconds, :from => User::U_FROM[:WEB])
        cookies[:first] = {:value => "1", :path => "/", :secure  => false}
      else
        ActionLog.login_log(@user.id)
        if @user.access_token.nil? || @user.access_token=="" || @user.access_token!=access_token
          @user.update_attributes(:access_token=>access_token,:end_time=>Time.now+expires_in.seconds)
        end
      end
      cookies[:user_id] ={:value =>@user.id, :path => "/", :secure  => false}
      cookies[:user_name] ={:value =>@user.username, :path => "/", :secure  => false}
      user_role?(cookies[:user_id])
      data=true
    rescue
      data=false
    end
    respond_to do |format|
      format.json {
        render :json=>data
      }
    end
  end



end
