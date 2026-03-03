class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.references :studio, null: false, foreign_key: true
      t.string :name
      t.string :category

      t.timestamps
    end
  end
end
