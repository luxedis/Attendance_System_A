require 'csv'
bom = "\uFEFF" # 4行目を使う為の定義

CSV.generate(bom, encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv| # 文字化け防止のオプション
  csv_column_names = ["日付","曜日","出社時間","退社時間"]
  csv << csv_column_names
  @attendances.each do |day|
    csv_column_values = [
      l(day.worked_on, format: :short),
      $days_of_the_week[day.worked_on.wday],
      if day.started_at.present? # nil
        l(day.started_at.floor_to(15.minutes), format: :time) # ja.ymlの時間を使う, floor_toで15分に丸める
      else
        ""
      end,
      if day.finished_at.present?
        l(day.finished_at.floor_to(15.minutes), format: :time)
      else
        ""
      end,
    ]
    csv << csv_column_values
  end
end