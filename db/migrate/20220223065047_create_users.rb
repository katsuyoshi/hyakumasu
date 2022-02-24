class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :user_id
      t.string :state, default: "idle"
      t.integer :level, default: 1
      t.string :col_numbers_str
      t.string :row_numbers_str

      t.timestamps
    end
  end
end
