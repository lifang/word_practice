# encoding: utf-8
module Constant
  SERVER_PATH = "http://localhost:3000"

  BACK_SERVER_PATH = "http://localhost:3001"
  
  #项目文件目录
  PUBLIC_PATH = "#{Rails.root}/public"
  
  #新单词上限
  NEW_WORDS_SUM = 10

  #用户XML中总单词上限
  LIMIT_WORDS_SUM = 200

  #新浪微博应用信息 gankao@hotmail.com  comdosoft2011
  SINA_CLIENT_ID = "3987186573"
  
  #人人应用信息  wangguanhong@hotmail.com  comdo2010
  RENREN_CLIENT_ID = "182012"
  RENREN_API_KEY = "98a6ed88bccc409da12a8abe3ebec3c5"
  RENREN_API_SECRET = "0d19833c0bc34a27a58786c07ef8d9fb"

  #每一步的相隔天数以及持续天数  new->step1 = [1,0] , step1->step2 = [2,1] , step2->step3 = [4,2] , step3->step4 = [8,4]
  REVIEW_STEP = [[1,0],[2,1],[4,2],[8,4]]

end
