class CreateAttendances < ActiveRecord::Migration[5.1]
  def change
    create_table :attendances do |t|
      t.date :worked_on
      t.datetime :started_at
      t.datetime :finished_at
      t.string :note
      t.datetime :scheduled_end_time # 終了予定時間
      t.boolean :overtime_next_day # 翌日
      t.string :overtime_detail # 業務処理内容
      t.string :overtime_confirmation # 残業申請モーダルの上長の名前
      t.string :overtime_status # 残業申請の状態(申請中、なし、承認、否認)
      t.boolean :change # _edit_apprlval_overtimeにある残業申請/上長承認ﾓｰﾀﾞﾙの"変更"のcheckboxのカラム
      t.datetime :before_started_at # 勤怠変更申請の変更前の開始時間
      t.datetime :before_finished_at # 勤怠変更申請の変更前の終了時間
      t.datetime :edit_started_at # 勤怠変更申請の変更用の開始時間
      t.datetime :edit_finished_at # 勤怠変更申請の変更用の終了時間
      t.boolean :edit_next_day # 勤怠変更申請の変更後の'翌日'
      t.string :edit_status # 勤怠変更申請の(申請中、なし、承認、否認)
      t.string :edit_confirmation # 勤怠編集画面で申請する上長のカラム
      t.date :approval_date # 勤怠ログで必要になる承認日
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end