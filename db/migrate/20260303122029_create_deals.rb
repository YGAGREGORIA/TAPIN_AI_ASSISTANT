class CreateDeals < ActiveRecord::Migration[8.1]
  def change
    create_table :deals do |t|
      t.references :studio, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.boolean :active

      t.timestamps
    end
  end
end
