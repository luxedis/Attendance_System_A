class UsersController < ApplicationController
  
  def show
    @user = User.find(parmas[:id])
  end
  
  def new
    @user = User.new # ユーザーオブジェクトを生成し、インスタンス変数に代入する。
  end
end
