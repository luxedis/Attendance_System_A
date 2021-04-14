class CreateAttendances < ActiveRecord::Migration[5.1]
  def change
    create_table :attendances do |t|
      t.date :worked_on
      t.datetime :started_at
      t.datetime :finished_at
      t.string :note
      t.datetime :scheduled_end_time # 終了予定時間
      t.boolean :overwork_next_day # 翌日
      t.string :overwork_detail # 業務処理内容
      t.string :overwork_confirmation # 支持者承認印
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end