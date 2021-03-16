class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :affiliation # 所属
      t.integer :employee_number  # 社員番号
      t.string :uid # カードID
      t.time :basic_work_time, default: Time.current.change(hour: 8, min: 0, sec: 0)  # 基本勤務時間
      t.time :designated_work_start_time, default: Time.current.change(hour: 9, min: 0, sec: 0)  # 指定勤務開始時間
      t.time :designated_work_end_time, default: Time.current.change(hour: 18, min: 0, sec: 0)  # 指定勤務終了時間

      t.timestamps
    end
  end
end
