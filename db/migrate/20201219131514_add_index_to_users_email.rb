class AddIndexToUsersEmail < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :email, unique: true # ユーザー検索時に使用するemail一覧
  end
end
