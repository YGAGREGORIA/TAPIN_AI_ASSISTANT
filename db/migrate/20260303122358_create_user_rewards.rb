class CreateUserRewards < ActiveRecord::Migration[8.1]
  def change
    create_table :user_rewards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reward, null: false, foreign_key: true
      t.integer :progress
      t.boolean :redeemed

      t.timestamps
    end
  end
end
