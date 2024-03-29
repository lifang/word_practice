#encoding: utf-8
class LoginsController < ApplicationController
  include LoginsHelper
  respond_to :html, :xml, :json


  def request_qq_web
    redirect_to "#{LoginsHelper::REQUEST_URL_QQ}?#{LoginsHelper::REQUEST_ACCESS_TOKEN.map{|k,v|"#{k}=#{v}"}.join("&")}"
  end

  def respond_qq
    render :inline=>"<script type='text/javascript'>window.location.href=window.location.toString().replace('#','?').replace('respond_qq','manage_qq_web');</script>"
  end

  def manage_qq_web
    begin
      access_token=params["access_token"]||params["?access_token"]
      expires_in=params[:expires_in].to_i
      openid_url="https://graph.z.qq.com"
      openid_para="/moc2/me?access_token=#{access_token}"
      request_openid=get_openid_http(openid_url,openid_para)
      openid=request_openid.split("openid=")[1]
      @user= User.find_by_open_id(openid)
      if @user.nil?
        user_url="https://graph.qq.com"
        user_route="/user/get_user_info?access_token=#{access_token}&oauth_consumer_key=#{LoginsHelper::APPID}&openid=#{openid}"
        user_info=create_get_http(user_url,user_route)
        user_info["nickname"]="qq用户" if user_info["nickname"].nil?||user_info["nickname"]==""
        @user=User.create(:code_type=>'qq',:name=>user_info["nickname"], :username=>user_info["nickname"],
          :open_id=>openid , :access_token=>access_token, :end_time=>Time.now+expires_in.seconds, :from => User::U_FROM[:WEB])
      else
        if @user.access_token.nil? || @user.access_token=="" || @user.access_token!=access_token
          @user.update_attributes(:access_token=>access_token,:end_time=>Time.now+expires_in.seconds)
        end
      end
      user_word=@user.init_word_list(2)
      cookies[:user_id] ={:value =>@user.id, :path => "/", :secure  => false,:expires =>Time.now.end_of_day}
      cookies[:user_name] ={:value =>@user.username, :path => "/", :secure  => false,:expires =>Time.now.end_of_day}
      user_word.update_attributes(:login_time=>Time.now)
      unless user_word.study_role.nil?
        render :inline=>"<script type='text/javascript'>window.location.href='/words';</script>"
      else
        render :inline=>"<script type='text/javascript'>window.location.href='/logins/lead_one';</script>"
      end
    rescue
      render :inline =>"<script type='text/javascript'>window.location.href='/';</script>"
    end
  
  end


  def request_sina
    redirect_to "https://api.weibo.com/oauth2/authorize?client_id=#{Constant::SINA_CLIENT_ID}&redirect_uri=#{Constant::SERVER_PATH}/logins/respond_sina&response_type=token&display=mobile"
  end

  def respond_sina
    if cookies[:oauth2_url_generate]
      begin
        cookies.delete(:oauth2_url_generate)
        #发送微博
        access_token=params[:access_token]
        uid=params[:uid]
        expires_in=params[:expires_in].to_i
        response = sina_get_user(access_token,uid)
        @user=User.find_by_code_id_and_code_type("#{response["id"]}","sina")
        if @user.nil?
          @user=User.create(:code_id=>"#{response["id"]}", :code_type=>'sina',
            :name=>response["screen_name"], :username=>response["screen_name"], :access_token=>access_token,
            :end_time=>Time.now+expires_in.seconds, :from => User::U_FROM[:WEB])
        else
          if @user.access_token.nil? || @user.access_token=="" || @user.access_token!=access_token
            @user.update_attributes(:access_token=>access_token,:end_time=>Time.now+expires_in.seconds)
          end
        end
        user_word=@user.init_word_list(2)
        cookies[:user_name] = {:value =>@user.username, :path => "/", :secure  => false,:expires =>Time.now.end_of_day}
        cookies[:user_id] = {:value =>@user.id, :path => "/", :secure  => false,:expires =>Time.now.end_of_day}
        user_word.update_attributes(:login_time=>Time.now)
        unless user_word.study_role.nil?
          render :inline=>"<script type='text/javascript'>window.location.href='/words';</script>"
        else
          render :inline=>"<script type='text/javascript'>window.location.href='/logins/lead_one';</script>"
        end
      rescue
        render :inline =>"<script type='text/javascript'>window.location.href='/';</script>"
      end
    else
      cookies[:oauth2_url_generate]="replace('#','?')"
      render :inline=>"<script type='text/javascript'>window.location.href=window.location.toString().replace('#','?');</script>"
    end
  end

  def request_renren
    redirect_to "http://graph.renren.com/oauth/authorize?response_type=token&client_id=#{Constant::RENREN_CLIENT_ID}&redirect_uri=#{Constant::SERVER_PATH}/logins/respond_renren&display=mobile"
  end

  def respond_renren
    render :inline=>"<script type='text/javascript'>window.location.href=window.location.toString().replace('#','?').replace('respond_renren','manage_renren');</script>"
  end

  def manage_renren
    begin
      access_token=params["access_token"]||params["?access_token"]
      expires_in=params[:expires_in].to_i
      response = renren_get_user(access_token)[0]
      unless response["uid"]
        redirect_to "/"
        return false
      end
      @user=User.find_by_code_id_and_code_type("#{response["uid"]}","renren")
      if @user.nil?
        @user=User.create(:code_id=>response["uid"],:code_type=>'renren',:name=>response["name"], :username=>response["name"],
          :access_token=>access_token, :end_time=>Time.now+expires_in.seconds, :from => User::U_FROM[:WEB])
      else
        if @user.access_token.nil? || @user.access_token=="" || @user.access_token!=access_token
          @user.update_attributes(:access_token=>access_token,:end_time=>Time.now+expires_in.seconds)
        end
      end
      user_word=@user.init_word_list(2)
      cookies[:user_name] ={:value =>@user.username, :path => "/", :secure  => false,:expires =>Time.now.end_of_day}
      cookies[:user_id] ={:value =>@user.id, :path => "/", :secure  => false,:expires =>Time.now.end_of_day}
      user_word.update_attributes(:login_time=>Time.now)
      unless user_word.study_role.nil?
        render :inline=>"<script type='text/javascript'>window.location.href='/words';</script>"
      else
        render :inline=>"<script type='text/javascript'>window.location.href='/logins/lead_one';</script>"
      end
    rescue
      render :inline =>"<script type='text/javascript'>window.location.href='/';</script>"
    end
  end

  def lead_one
    @user_word=UserWordRelation.find_by_user_id( cookies[:user_id])
  end

  def user_option
    param={:study_role=>params[:words].to_i,:timer=>"#{params[:answer_time]},#{params[:read_time]}"}
    UserWordRelation.find_by_user_id( cookies[:user_id]).update_attributes(param)
    redirect_to "/words"
  end
  
end
