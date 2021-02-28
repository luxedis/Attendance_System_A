class AddAdminToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :admin, :boolean, default: false # 管理者
    add_column :users, :superior, :boolean, default: false # 上長
  end
end