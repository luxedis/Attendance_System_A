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
end