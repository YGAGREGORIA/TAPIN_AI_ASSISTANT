class CreateStudios < ActiveRecord::Migration[8.1]
  def change
    create_table :studios do |t|
      t.string :name
      t.string :owner_email
      t.text :location

      t.timestamps
    end
  end
end
