# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
puts "Seeding..."
# --- Users (Devise) ---
user =
  User.find_or_create_by!(email: "demo@gmail.com") do |u|
    u.password = "password123"
    u.password_confirmation = "password123"
    u.first_name = "Demo"
    u.last_name = "User"
    u.phone_number = 49123456
  end
# --- Studio (required by your schema: lots of tables need studio_id) ---
studio =
  Studio.find_or_create_by!(name: "TAPIN Studio") do |s|
    s.location = "Hamburg"
    s.owner_email = "owner@gmail.com"
  end
# --- Courses ---
course_names = [
  ["HIIT Express", "fitness"],
  ["Yoga Flow", "mind-body"],
  ["Boxing Basics", "combat"]
]
courses = course_names.map do |name, category|
  Course.find_or_create_by!(studio: studio, name: name) do |c|
    c.category = category
  end
end
# --- Deals ---
deals_data = [
  ["2-for-1 Trial Week", "Bring a friend and train together this week.", true],
  ["10% off Monthly", "Save 10% on your first monthly membership.", true],
  ["Free Protein Shake", "Get one free shake after your next class.", false]
]
deals_data.each do |title, description, active|
  Deal.find_or_create_by!(studio: studio, title: title) do |d|
    d.description = description
    d.active = active
  end
end
# --- Rewards ---
rewards_data = [
  ["Free Class", 3],
  ["Free Smoothie", 5],
  ["TAPIN Hoodie", 10]
]
rewards_data.each do |name, required_checkins|
  Reward.find_or_create_by!(studio: studio, name: name) do |r|
    r.required_checkins = required_checkins
  end
end
# --- Check-ins (for "check-in" intent) ---
# create a few check-ins for the demo user
existing = CheckIn.where(user: user, studio: studio).count
to_create = [5 - existing, 0].max
to_create.times { CheckIn.create!(user: user, studio: studio) }
# --- Chat + Messages (so you can see a saved conversation immediately) ---
chat =
  Chat.order(created_at: :desc).find_by(user: user, studio: studio) ||
  Chat.create!(user: user, studio: studio, title: "Chat 1")
Message.find_or_create_by!(chat: chat, role: "assistant", content: "Hi. How can I help?")
Message.find_or_create_by!(chat: chat, role: "user", content: "Show me my check-ins")
Message.find_or_create_by!(chat: chat, role: "assistant", content: "You have #{CheckIn.where(user: user).count} check-ins.")
puts "Seed complete."
puts "Demo login:"
puts "  email: demo@tapin.app"
puts "  password: password123"
puts "Studio: #{studio.name}"
puts "Chat id: #{chat.id}"


studio = Studio.first || Studio.create!(name: "Demo Studio")

user = User.find_or_create_by!(email: "demo@gmail.comab") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.first_name = "Demo"
  u.last_name = "User"
  u.phone_number = "49123456"
  u.studio = studio
end

puts "created User with the Studio"
