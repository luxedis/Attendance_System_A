class UsersController < ApplicationController
  
  def index
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def new
    @user = User.new # ユーザーオブジェクトを生成し、インスタンス変数に代入する。
  end
  
  def create
    @user = User.new(user_params)
    if @user.save
      flash[:success] = "新規作成に成功しました"
      redirect_to @user
    else
      render :new
    end
  end
  
  
  private
  
    def user_params
      params.require(:user).permit(:name, :email, :password, :passwore_confirmation)
    end
  
end
