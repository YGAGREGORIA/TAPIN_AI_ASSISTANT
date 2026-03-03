class RemoveEmailAdressFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :email_address, :string
  end
end

