class AddDetailsToStudios < ActiveRecord::Migration[8.1]
  def change
    add_column :studios, :address, :string
    add_column :studios, :phone, :string
    add_column :studios, :email, :string
    add_column :studios, :opening_hours, :text
    add_column :studios, :facilities, :text
    add_column :studios, :pricing, :text
  end
end
