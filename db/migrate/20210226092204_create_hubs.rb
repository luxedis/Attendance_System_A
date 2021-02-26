class CreateHubs < ActiveRecord::Migration[5.1]
  def change
    create_table :hubs do |t|
      t.integer :hub_number
      t.string :name
      t.string :attendance

      t.timestamps
    end
  end
end
