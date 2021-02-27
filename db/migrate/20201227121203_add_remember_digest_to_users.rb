class AddRememberDigestToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :remember_digest, :string
    add_column :users, :affiliation, :string # 所属
    add_column :users, :employee_number, :integer # 社員番号
    add_column :users, :uid, :string # カードID
    add_column :users, :basic_work_time, :datetime # 基本勤務時間
    add_column :users, :designated_work_start_time, :datetime # 指定勤務開始時間
    add_column :users, :designated_work_end_time, :datetime # 指定勤務終了時間
    add_column :users, :superior, :boolean, default: false # 上長
  end
end
