class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :update_all_users_basic_info] # overtime_request
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :update_all_users_basic_info] # overtime_request
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:destroy, :edit_basic_info, :update_basic_info, :update_all_users_basic_info]
  before_action :admin_or_correct_user, only: :show
  before_action :set_one_month, only: :show
  
require 'csv'

  def index
    # debugger
    @users = User.all
    @users = User.paginate(page: params[:page]) # ここでページネートしている
    if params[:name].present? # index.html10行目付近でtext_field :nameとしているからここのパラメータがnameになる。パラメータが空の状態がデフォルトだから、もしパラメータにnameカラムが存在したら、となる。
      @users = @users.search(params[:name]) #indexアクション(10行目)でページネート済みのユーザーを、更に検索するという意→先頭の@users。
    end
  end
  
  def show
    redirect_to users_url if current_user.admin? # 管理者の場合はユーザー一覧画面へ
    
    @worked_sum = @attendances.where.not(started_at: nil).count
    respond_to do |format|
      format.html
      format.csv do
        send_data render_to_string, filename: "勤怠一覧表.csv", type: :csv
      end
    end
    # @approval_manager_notice = Attendance.where('#': "申請中", overtime)
    # @attendance_change_notice = Attendance.where('#': "申請中", overtime)
    @superiors = User.where(superior: true).where.not(id: @user.id)
    @approval_monthly_report = Attendance.where(monthly_confirmation: @user.name, monthly_status: "申請中").size
    @approval_monthly_edit = Attendance.where(edit_confirmation: @user.name, edit_status: "申請中").size
    @overtime_notice = Attendance.where(overtime_confirmation: @user.name, overtime_status: "申請中").size # 件数の表示のみ
    @monthly_attendance = @user.attendances.find_by(worked_on: @first_day)
  end
  
  def new
    @user = User.new # ユーザーオブジェクトを生成し、インスタンス変数に代入する。
  end
  
  def create
    @user = User.new(user_params)
    if @user.save
      log_in (@user) # log_inはsessions_contorllerのloginは走る/保存成功語、ログインします。
      flash[:success] = '新規作成に成功しました'
      redirect_to @user
    else
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @user.update_attributes(user_params)
      flash[:success] = "アカウント情報を更新しました。"
      redirect_to @user
    else 
      render :edit
    end
  end
  
  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end
  
  def edit_basic_info
  end
  
  def update_basic_info
    if @user.update_attributes(basic_info_params) # (department: params[:user][:department], basic_time: params[:user][:basic_time], work_time: params[:user][:basic_time])
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end
  
  # 出勤中の社員一覧
  def at_work_index
    @users = User.includes(:attendances).references(:attendances)
    .where('attendances.started_at IS NOT NULL').where('attendances.finished_at IS NULL')                                       
    # byebug
  end
  
  # CSVファイルのインポート
  def import
    User.import(params[:file])
    redirect_to users_url
  end
  
  # 各お知らせモーダル内の勤怠確認ボタン
  def confirm_one_month
    @user = User.find(params[:id])
    @first_day = params[:date].to_date.beginning_of_month
    @last_day = @first_day.end_of_month
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    @monthly_attendance = @user.attendances.find_by(worked_on: @first_day)
  end

  private
  
  def user_params
    params.require(:user).permit(:name, :email, :department, :password, :password_confirmation)
  end
  
  def basic_info_params
    binding.pry# debugger
    params.require(:user).permit(:department, :basic_time, :work_time)
  end
  
  def update_all_users_basic_info_params
    params.require(:user).permit(:basic_time, :work_time)
  end
  
  # def search_params
  #   params.fetch(:search, {}).permit(:name) # fetch/
  # end
  
  # beforeフィルター
  def admin_or_correct_user
    # @user = User.find(params[:id]) if @user.blank? #id1のユーザーを探してそのレコードを@userに入れてあげるbefore_actionでset_use してるから
    unless current_user?(@user) || current_user.admin? #current_userが@userじゃない、current_userがadminだから入らないunless文はどちらかがtuireだと入らない
      flash[:danger] = "編集権限がありません。"
      redirect_to(root_url)
    end
  end
  
  # # paramsハッシュからユーザーを取得します
  # def set_user
  #   @user = User.find(params[:id])
  # end # set_userアクションをattendancesコントローラでも使う為、applicationコントローラへ引越し
  
#   # ログイン済みのユーザーか確認する。
#   def logged_in_user
#     unless logged_in?
#       store_location
#       flash[:danger] = "ログインしてください。"
#       redirect_to login_url
#     end
#   end
  
#   # アクセスしたユーザーが現在ログインしているユーザーか確認します。
#   def correct_user
#     redirect_to(root_url) unless current_user?(@user)
#   end
  
#   # システム管理権限所有��か判定します。
#   def admin_user
#     redirect_to root_url unless current_user.admin?
#   end
end