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
        flash[:danger] = UPDATE_ERROR_MSG # "勤怠登録に失敗しました。やり直してください。"
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
  def edit_overtime_request
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id]) # idの値が一致するレコードを探す
    @superiors = User.where(superior: true).where.not(id: @user.id) # 上記レコードのuser_idを元にユーザー情報を探す
  end

  # 残業申請のupdate
  def update_overtime_request
    @user = User.find(params[:user_id])
    @attendance =  Attendance.find(params[:id]) # attendanceのデータにはuser_idが入っている。userのattendanceだから。
    if params[:attendance][:overtime_detail].blank? && params[:attendance][:overtime_confirmation].present?
      flash[:danger] = "業務処理内容を入力してください。"
      redirect_to @user
    elsif params[:attendance][:overtime_confirmation].blank? && params[:attendance][:overtime_detail].present?
      flash[:danger] = "上長を選択してください。"
      redirect_to @user
    elsif params[:attendance][:overtime_detail].blank? && params[:attendance][:overtime_confirmation].blank? # elsifは条件式だから、if文だから、同行に書いてOK
      flash[:danger] = "未入力の項目があります"
      redirect_to @user
    else
      params[:attendance][:overtime_status] = "申請中"
      @attendance.update_attributes(overtime_params) # ここで選択した上長のデータが入っている/private内のovertime_paramsをここで更新
      # debugger
      flash[:success] = "残業を申請しました"
      redirect_to @user
    end
  end

  # 上長が残業申請を承認するモーダル
  def edit_approval_overtime
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(overtime_confirmation: @user.name, overtime_status: "申請中").order(:user_id).group_by(&:user_id)
    # ⬆️自分宛(上長を入れいてるカラムだから、上長しかありえない)に申請されいている申請中のattendanceレコード/.order＝昇順/.group_by集合の要素の数だけ繰り返し処理してチェックする
  end

  # "残業申請のお知らせ"モーダル更新
  def update_approval_overtime
    ActiveRecord::Base.transaction do
      o1 = 0
      o2 = 0
      o3 = 0
      approval_overtime params.each do |id, item|
        if (item[:change] == "1") && (item[:overtime_status] == "申請中") #申請中だと更新しない
          attendance = Attendance.find(id)
            if item[:overtime_status] == "なし"
              o1 += 1
              item[:scheduled_end_time] = nil
              item[:overtime_next_day] = nil
              item[:overtime_detail] = nil
              item[:overtime_confirmation] = nil
            elsif item[:overtime_status] == "承認"
              o2 += 1
              attendance.indicater_check_anser = "残業申請を承認しました"
            elsif item[:overtime_status] == "否認"
              o3 += 1
            end
            attendance.update_attributes!(item)
          end
        end
      end
      if o1,o2,o3 が全て0なら
        flash[:success] = "更新はありませんでした。"
      end
      flash[:success] = "残業申請#{o1}件,#{o2}件承認,#{o3}件否認しました。"
      redirect_to user_url(date: params[:date])
    end
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to edit_overtime_notice_user_attendance_url(@user, item)
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

    def overtime_params
      params.require(:attendance).permit(:scheduled_end_time, :overtime_next_day, :overtime_detail, :overtime_confirmation, :overtime_status)
    end

    # def approval_overtime_params
    #   params.require(:user).permit(attendances: [:overtime_status, :change])[:attendances]
    # end
end