module ApplicationHelper
  # ページごとにタイトルを返す
  def  full_title(page_name = "") # メソッドと引き数の定義
    base_title = "AttendanceSystemB" # 変数にアプリの基本名を代入
    if page_name.empty? # 引数の受取を判定
      base_title # 引数page_nameが空の場合base_titleのみ返す
    else # 引数page_nameが空でない場合
      page_name + " | " + base_title # 文字列を連結して返す
    end
  end
end
