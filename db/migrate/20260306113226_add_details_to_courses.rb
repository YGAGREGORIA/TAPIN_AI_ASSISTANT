class AddDetailsToCourses < ActiveRecord::Migration[8.1]
  def change
    add_column :courses, :description, :text
    add_column :courses, :schedule, :string
    add_column :courses, :duration, :integer
    add_column :courses, :difficulty, :string
    add_column :courses, :benefits, :text
    add_column :courses, :what_to_bring, :text
    add_column :courses, :what_to_wear, :text
    add_column :courses, :recovery_tips, :text
    add_column :courses, :best_for, :text
  end
end
