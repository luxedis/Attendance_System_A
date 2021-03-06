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
    @superiors = User.where(superior: true).where.not(id: @user.id)
  end
  
  def update_one_month
    ActiveRecord::Base.transaction do # トランザクション(分割できないワンセット処理の事)の開始
      attendances_params.each do |id, item|
        if item[:edit_confirmation].present? # 上長の入力がある項目のみを拾う
          if item[:edit_started_at].present? && item[:edit_finished_at].blank?
            flash[:danger] = "退勤時間が入力されていません。"
            redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
          elsif item[:edit_started_at].blank? && item[:edit_finished_at].present?
            flash[:danger] = "出社時間が入力されていません。"
            redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
          elsif item[:edit_started_at].blank? && item[:edit_finished_at].blank?
            flash[:danger] = "出勤時間、退勤時間を入力してください。"
            redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
          elsif (item[:edit_next_day] == "0") && (item[:edit_started_at] > item[:edit_finished_at]) # &&つける時は両側に()をつけること
            flash[:danger] = "出勤時間より早い退勤時間は無効です。"
            redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
          elsif item[:edit_confirmation].blank?
            flash[:danger] = "指示者を入力してください。"
            redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
          # elsif item[:edit_confirmation].blank?  上長の入力がある項目のみ扱っているので、上記の該当コードがなければ左記を復活させる
          #   flash[:danger] = "上長を選択してください。"
          #   redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
          elsif item[:note].blank?
            flash[:danger] = "備考を入力してください。"
            redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
          end
          attendance = Attendance.find(id)
          item[:edit_status] = "申請中"
          attendance.update_attributes!(item)
        end
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
      params[:attendance][:overtime_status] = "申請中" #申請中の物だけモーダルに表示したいから
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
    @user = User.find(params[:user_id])
    ActiveRecord::Base.transaction do
      n1 = 0
      n2 = 0
      n3 = 0
      approval_overtime_params.each do |id, item|
        if (item[:change] == "1") # なし,承認,否認は== 1と定義、申請中だと更新せず、1なら更新する。以下処理
          attendance = Attendance.find(id)
          if item[:overtime_status] == "なし" # 残業申請を無かったことにする'なし'
            n1 += 1 # 終了予定時間,翌日,業務処理内容,モーダル内の上長の名前
            item[:scheduled_end_time] = nil
            item[:overtime_next_day] = nil
            item[:overtime_detail] = nil
            item[:overtime_confirmation] = nil
          elsif item[:overtime_status] == "承認"
            n2 += 1
          elsif item[:overtime_status] == "否認"
            n3 += 1
          end
          item[:change] = "0" # 過去の承認で変更にチェックを入れたのが、そのまま残ってしまうのを避ける為
          attendance.update_attributes!(item) # 例外処理を返す為の'!'
        end
        # o1,o2,o3が全て0なら更新しない        
      end
      flash[:success] = "残業申請　なし#{n1}件、承認#{n2}件、否認#{n3}件"
      redirect_to user_url(@user) and return # リダイレクトしたらここで終わりなさい、の意味(and return)
    end
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to user_url(@user) and return
  end

  # ◯◯からの(1ヶ月分の)勤怠変更申請モーダル表示
  def approval_monthly_edit
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(edit_confirmation: @user.name, edit_status: "申請中").order(:user_id).group_by(&:user_id)
  end

  # 勤怠変更の承認モーダル更新
  def update_approval_monthly_edit
    @user = User.find(params[:user_id])
    ActiveRecord::Base.transaction do
      n1 = 0
      n2 = 0
      n3 = 0
      approval_monthly_edit_params.each do |id, item|
        if (item[:change] == "1") # なし,承認,否認は== 1と定義、申請中だと更新せず、1なら更新する。以下処理
          attendance = Attendance.find(id) # idで更新するレコードを特定する。
          if item[:edit_status] == "承認"
            n1 += 1
            if attendance.before_started_at.nil? # 変更する項目だから、一番最初の時間を残したい。before_started_atがカラだったstarted_atを保存する
              attendance.before_started_at = attendance.started_at # attendanceの中に更新するレコードがいる/ログ変更前の記録を残したい
            end
            if attendance.before_finished_at.nil?
              attendance.before_finished_at = attendance.finished_at
            end
            attendance.started_at = attendance.edit_started_at
            attendance.finished_at = attendance.edit_finished_at
            attendance.approval_date = Date.today # 承認日付、ログ用
          elsif item[:edit_status] == "なし"
            n2 += 1
           # if (attendance.edit_status == "承認") || (attendance.edit_status == "否認") # 前回承認or否認して今回なしにした時の為に、記録を残したい。
              # debugger
              # item[:edit_status] = attendance.edit_status # これをしてあげないとitem[:edit_status] =="なし"だけ残ってしまう.
            # else
              # debugger
              attendance.edit_started_at = nil # "承認"or"否認"の場合は以下をnilにする
              attendance.edit_finished_at = nil
              attendance.edit_next_day = nil
              attendance.note = nil
              attendance.edit_confirmation = nil
            # end
          elsif item[:edit_status] == "否認"
            n3 += 1
          end
          item[:change] = "0" # 過去の承認で変更にチェックを入れたのが、そのまま残ってしまうのを避ける為
          attendance.update_attributes!(item) # 例外処理を返す為の'!'
        end
        # o1,o2,o3が全て0なら更新しない        
      end
      flash[:success] = "勤怠変更申請　なし#{n2}件、承認#{n1}件、否認#{n3}件"
      redirect_to user_url(@user) and return # リダイレクトしたらここで終わりなさい、の意味(and return)
    end
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to user_url(@user) and return
  end

  # 1ヶ月分の勤怠承認/上長への申請ボタン
  def monthly_approval_request
    @user = User.find(params[:id]) # @userでuser_idが特定できる
    attendance = @user.attendances.find_by(worked_on: params[:user][:worked_on]) # showのworked_on,195行目とセット,月初日のレコードを更新したい
    if params[:user][:monthly_confirmation].blank? #
      flash[:danger] = "所属長を選択してください。"
    else
      attendance.update_attributes!(monthly_approval_params) # @をつけるのはインスタンス変数にするためで、viewファイルに渡すためで、ここはviewに渡さないから@いらない
      flash[:success] = "#{@user.name}の1ヶ月分の申請をしました。"
    end
    redirect_to user_url(@user)
  end

  # 1ヶ月分の勤怠
  def approval_monthly_report
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(monthly_confirmation: @user.name, monthly_status: "申請中").order(:user_id).group_by(&:user_id)
  end

  # 1ヶ月分の勤怠承認
  def update_approval_monthly_report
    @user = User.find(params[:user_id])
    ActiveRecord::Base.transaction do
      n1 = 0
      n2 = 0
      n3 = 0
      approval_monthly_report_params.each do |id, item| # 依頼来るのが複数人だからeachする必要がある
        if (item[:change] == "1") # なし,承認,否認は== 1と定義、申請中だと更新せず、1なら更新する。以下処理
          attendance = Attendance.find(id)
          if item[:monthly_status] == "なし" # 残業申請を無かったことにする'なし'
            n1 += 1 # 終了予定時間,翌日,業務処理内容,モーダル内の上長の名前
          elsif item[:monthly_status] == "承認"
            n2 += 1
          elsif item[:monthly_status] == "否認"
            n3 += 1
          end
          item[:change] = "0" # 過去の承認で変更にチェックを入れたのが、そのまま残ってしまうのを避ける為
          attendance.update_attributes!(item) # 例外処理を返す為の'!'
        end
        # o1,o2,o3が全て0なら更新しない        
      end
      flash[:success] = "所属長承認申請　なし#{n1}件、承認#{n2}件、否認#{n3}件"
      redirect_to user_url(@user) and return # リダイレクトしたらここで終わりなさい、の意味(and return)
    end
    redirect_to @user
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、変更をキャンセルしました。"
    redirect_to @user
  end

  def attendance_log
    @user = User.find(params[:user_id])
    if params["select_year(1i)"].present? && params["select_month(2i)"].present?
      @first_day = Date.new(params["select_year(1i)"].to_i, params["select_month(2i)"].to_i, params["select_month(3i)"].to_i)
    else
      @first_day = Date.today.to_date.beginning_of_month # 選択された日か、月初日になるから
    end
    @last_day = @first_day.end_of_month
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).where(edit_status: "承認").order(worked_on: "ASC") # 日付順
  end


  private
    # 残業申請の更新
    def overtime_params
      params.require(:attendance).permit(:scheduled_end_time, :overtime_next_day, :overtime_detail, :overtime_confirmation, :overtime_status)
    end

    # "残業申請のお知らせ"モーダル更新
    def approval_overtime_params
      params.require(:user).permit(attendances: [:scheduled_end_time, :overtime_next_day, :overtime_detail, :overtime_confirmation, :overtime_status, :change])[:attendances]
    end

    # 勤怠変更申請の勤怠情報を扱う
    def attendances_params
      params.require(:user).permit(attendances: [:edit_started_at, :edit_finished_at, :edit_next_day, :note, :edit_confirmation, :edit_status])[:attendances]
    end
    
    # 勤怠変更申請の更新情報
    def approval_monthly_edit_params
      params.require(:user).permit(attendances: [:edit_status, :change])[:attendances]
    end

    # 1ヶ月分の勤怠承認/上長への申請ボタン
    def monthly_approval_params
      params.require(:user).permit(:worked_on, :monthly_status, :monthly_confirmation)
    end

    # 一ヶ月分勤怠申請承認
    def approval_monthly_report_params
      params.require(:user).permit(attendances: [:monthly_status, :change])[:attendances]
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