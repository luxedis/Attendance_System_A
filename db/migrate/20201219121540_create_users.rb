class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :affiliation # 所属
      t.integer :employee_number  # 社員番号
      t.string :uid # カードID
      t.time :basic_work_time  # 基本勤務時間
      t.time :designated_work_start_time  # 指定勤務開始時間
      t.time :designated_work_end_time  # 指定勤務終了時間

      t.timestamps
    end
  end
end
