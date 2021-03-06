require 'sinatra'
require 'passenger'
require 'sinatra/activerecord'
require 'sqlite3'
require 'json'
require 'will_paginate'
require 'dotenv'

class User < ActiveRecord::Base
    has_many :devices
    has_many :vlogs
end

class Device < ActiveRecord::Base
    belongs_to :user
end

class Vlog < ActiveRecord::Base
    belongs_to :user
end


# 특정 vlog_id의 detail을 볼 때 호출
get '/detail' do 
  d = Device.find_by_sns_token(params[:token])
  v = Vlog.find(params[:vlog_id])
  
  if d.user == v.user
    
    v.to_json

  else
    error = {:err_code => '001', 
             :err_msg => '권한이 없는 게시물 입니다.'}
    error.to_json
  end
end


#History View에서 호출할 때 사용할 것.
get '/list_by_filter' do
  device = Device.find_by_token(params[:token])
  unless device.nill?
    user = device.user
    unless user.nill?
      
      v = user.vlogs.where(:log_date => range(params[:filter_to_date],params[:filter_from_date], #문법 맞는지 확인 필요
                       :feeling => params[:filter_feeling])) # and조건이 아니라 or조건으로 걸어야 함
      
      #Pagination / :page 값을 Fuse에서 받아야 함
      v = paginate(:page => params[:page], :per_page => 30).to_json
      
    else   
      error = {:err_code => '002', 
        :err_msg => '가입되어있지 않은 User입니다.'}
      error.to_json   
    end
  else
    error = {:err_code => '003', 
      :err_msg => '등록되어 있지 않은 Device입니다.'}
    error.to_json 
  end
end

# Calender View에서 호출할 때 사용할 것. 
# 이를 기준으로 특정 날짜를 클릭했을 때, write로 redirect될 지, detail로 redirect될 지 결정된다.
get '/list_by_month' do
  device = Device.find_by_token(params[:token])
  unless device.nill?
    user = device.user
    unless user.nill?
      # :yesr와 :month는 Fuse에서 User가 선택한 값
      vlog.where(:user_id => user.id,
                :log_date.year => params[:yeaer], ### 문법에 맞는가??? 확인 필요...
                :log_date.month => params[:month], ### 문법에 맞는가??? 확인 필요...
                ).to_json      
      
    else   
      error = {:err_code => '002', 
        :err_msg => '가입되어있지 않은 User입니다.'}
      error.to_json   
    end
  else
    error = {:err_code => '003', 
      :err_msg => '등록되어 있지 않은 Device입니다.'}
    error.to_json 
  end
end
  
  
# Fuse에서 video 촬영 및 parameter 적용 후 최종 콘텐츠 등록
post '/submit' do  
  token = Token.find_by_token(params[:token])  
  user = token.first

  # 파일 저장하기
  v = Vlog.new
  v.create_date = Time.now
  v.log_date = params[:log_date]
  v.feeling = params[:feeling]
  v.tag = params[:tag]
  v.video_link = video_path
  v.thumbnail_link = thumb_path
  v.save
  
  v.to_json
end

