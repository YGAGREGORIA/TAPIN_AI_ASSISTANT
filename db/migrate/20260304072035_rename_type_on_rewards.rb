class RenameTypeOnRewards < ActiveRecord::Migration[8.1]
  def change
    rename_column :rewards, :type, :reward_type
  end
end
