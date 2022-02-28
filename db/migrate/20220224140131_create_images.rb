class CreateImages < ActiveRecord::Migration[6.1]
  def change
    create_table :images do |t|
      t.binary :data
      t.integer :step, default: 0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
