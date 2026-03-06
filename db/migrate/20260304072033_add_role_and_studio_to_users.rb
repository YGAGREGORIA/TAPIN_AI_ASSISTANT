class AddRoleAndStudioToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, default: "customer", null: false
    add_reference :users, :studio, null: true, foreign_key: true
  end
end
