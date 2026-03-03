class CreateRewards < ActiveRecord::Migration[8.1]
  def change
    create_table :rewards do |t|
      t.string :name
      t.string :type
      t.integer :required_checkins
      t.references :studio, null: false, foreign_key: true

      t.timestamps
    end
  end
end
