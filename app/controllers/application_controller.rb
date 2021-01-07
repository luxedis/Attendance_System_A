class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper
  
  $days_of_the_week = %w{日 月 火 水 木 金 土}
  
  # ページ出力前に1ヶ月分のデータの存在を確認・セットする
  def set_one_month
    @first_day = Date.current.beginning_of_month
    @last_day = @first_day.end_of_month
    one_month = [*@first_day..@last_day] # 対象月の日数を代入する
    # ユーザーに紐づく1ヶ月分のレコードを検索して取得する
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day)
    
    unless one_month.count == @attendances.count # それぞれの件数(日数)が一致するか評価する
      ActiveRecord::Base.transaction do # トランザクションの開始
        # 繰り返し処理により1ヶ月分の勤怠データを生成する
        one_month.each { |day| @user.attendances.create!(worked_on: day) }
    end
  end
  
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐
    flash[:danger] = "ページ情報の取得に失敗しました。再アクセスしてください。"
    redirect_to root_url
  end
end