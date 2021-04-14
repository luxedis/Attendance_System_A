class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
  
  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"
  
  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます!"
      else
        flash[:danger] = UPDATE_ERROR_MSG # "勤怠登録に失敗しました。やり直してください。""
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end
  
  def edit_one_month
  end
  
  def update_one_month
    # debugger
    ActiveRecord::Base.transaction do # トランザクション(分割できないワンセット処理の事)の開始
      attendances_params.each do |id, item|
        # debugger
        if item[:started_at].present? && item[:finished_at].blank?
          flash[:danger] = "退勤時間が入力されていません。"
          redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
        elsif item[:started_at].blank? && item[:finished_at].present?
          flash[:danger] = "出社時間が入力されていません。"
          redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
        end
        attendance = Attendance.find(id) # 242
        attendance.update_attributes!(item) # 失敗すると42行に飛ぶ。ここでモデルを見て、ヘルパーのバリデに引っかかった場合!で例外処理に飛ばす
      #   attendance.attributes = item # ここでは保存せず、アイテムのカラムをセットのみする1/1のidが242
      #   attendance.save!(context: :attendance_update) #ここで上記で更新した値をレコードに保存(同時にバリデーションを実行)
      end
    end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐 updateで例外処理がおきた
    # flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。<br>" + attendance.errors.full_messages.join("<br>")
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
  # 残業申請
  def edit_overwork_request
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @superiors = User.where(superior: true).where.not(id: @user.id)
  end

  # 残業申請のupdate
  def update_overwork_request
    @user = User.find(params[:user_id])
    @attendance =  @user.attendances.find(params[:id])
    if # params[:業務処理内容].blank? || params[:attendance][:指示者確認印]
      flash[:danger] = "未入力の項目があります"
    else
      # 残業申請中&&支持者承認印が未だの時="申請中"
      # 
      flash[:success] = "残業を申請しました"
    end
    redirect_to @user
  end

  private
    # 1ヶ月分の勤怠情報を扱う
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    end
    
    # beforeフィルター
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank? # params[:user_id]ではなくfind_by(id: params[:user_id])
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end
    end
end