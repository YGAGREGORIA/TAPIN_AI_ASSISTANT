class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.integer :phone_number
      t.string :email_address
      t.string :first_name
      t.string :last_name

      t.timestamps
    end
  end
end
