module UsersHelper
  
  # 勤怠基本情報を指定のフォーマットで返す
  def format_basic_info(time)
    format("%.2f", ((time.hour * 60) + time.min) / 60.0) # %.2fで小数点以下２桁指定しても、60.0と小数点指定しないと
  end
  
  def format_hour(time)
    format("%02d", time.hour) # 時間を整数で表す
  end
  
  def format_min(time)
    format("%02d", ((time.min / 15) * 15)) # time.minを15で掛けてから15で割る、計算式ミスってた。
  end

  def overtime_info(scheduled_time, end_time, next_day) # _edit_overtime_requestで(time_select,minute_step15)終了予定時間を15分刻みの表示に固定している
    if next_day == true # 翌日にチェックが入ると、次の日がtrueになる
      format("%.2f", ((scheduled_time.hour - end_time.hour) + (scheduled_time.min - end_time.min) / 60.0) + 24) # 深夜1時は25時だから、24足してあげる
    else
      format("%.2f", (scheduled_time.hour - end_time.hour) + (scheduled_time.min - end_time.min) / 60.0) # 翌日にチェックが入らなかった場合
    end
  end
end