puts "Seeding..."

# --- Studio ---
studio = Studio.find_or_create_by!(name: "TAPIN Studio") do |s|
  s.location = "Hamburg"
  s.owner_email = "admin@tapin.com"
end

# --- Admin user ---
admin = User.find_or_create_by!(email: "admin@tapin.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.first_name = "Studio"
  u.last_name = "Owner"
  u.role = "admin"
  u.studio = studio
end

# --- Demo customer ---
demo = User.find_or_create_by!(email: "demo@gmail.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.first_name = "Demo"
  u.last_name = "User"
  u.phone_number = 49123456
  u.role = "customer"
  u.studio = studio
end

# --- Additional customers (varied check-in patterns for admin tools) ---
customers_data = [
  { first_name: "Alice",   last_name: "Johnson", email: "alice@example.com",   checkins: 25, last_checkin_days_ago: 2 },
  { first_name: "Bob",     last_name: "Smith",   email: "bob@example.com",     checkins: 40, last_checkin_days_ago: 1 },
  { first_name: "Charlie", last_name: "Brown",   email: "charlie@example.com", checkins: 5,  last_checkin_days_ago: 45 },
  { first_name: "Diana",   last_name: "Prince",  email: "diana@example.com",   checkins: 18, last_checkin_days_ago: 60 },
  { first_name: "Eve",     last_name: "Davis",   email: "eve@example.com",     checkins: 9,  last_checkin_days_ago: 3 },
  { first_name: "Frank",   last_name: "Miller",  email: "frank@example.com",   checkins: 50, last_checkin_days_ago: 0 },
  { first_name: "Grace",   last_name: "Lee",     email: "grace@example.com",   checkins: 2,  last_checkin_days_ago: 90 },
  { first_name: "Hank",    last_name: "Wilson",  email: "hank@example.com",    checkins: 15, last_checkin_days_ago: 7 }
]

customers = customers_data.map do |data|
  user = User.find_or_create_by!(email: data[:email]) do |u|
    u.password = "password123"
    u.password_confirmation = "password123"
    u.first_name = data[:first_name]
    u.last_name = data[:last_name]
    u.role = "customer"
    u.studio = studio
  end

  if user.check_ins.where(studio: studio).count == 0
    data[:checkins].times do
      CheckIn.create!(
        user: user,
        studio: studio,
        created_at: rand(data[:last_checkin_days_ago]..180).days.ago
      )
    end
  end

  user
end

# Demo user check-ins
existing = CheckIn.where(user: demo, studio: studio).count
[5 - existing, 0].max.times { CheckIn.create!(user: demo, studio: studio) }

# --- Courses ---
[
  ["HIIT Express", "fitness"],
  ["Yoga Flow", "mind-body"],
  ["Boxing Basics", "combat"],
  ["Pilates", "mind-body"],
  ["Spin Class", "cardio"],
  ["Meditation", "mind-body"]
].each do |name, category|
  Course.find_or_create_by!(studio: studio, name: name) do |c|
    c.category = category
  end
end

# --- Deals ---
[
  ["2-for-1 Trial Week", "Bring a friend and train together this week.", true],
  ["10% off Monthly", "Save 10% on your first monthly membership.", true],
  ["Free Protein Shake", "Get one free shake after your next class.", false]
].each do |title, description, active|
  Deal.find_or_create_by!(studio: studio, title: title) do |d|
    d.description = description
    d.active = active
  end
end

# --- Rewards ---
rewards = [
  ["Free Class", "perk", 3],
  ["Free Smoothie", "perk", 5],
  ["Bronze Badge", "badge", 10],
  ["Silver Badge", "badge", 25],
  ["Gold Badge", "badge", 50]
].map do |name, rtype, required|
  Reward.find_or_create_by!(studio: studio, name: name) do |r|
    r.reward_type = rtype
    r.required_checkins = required
  end
end

# --- User rewards (progress tracking) ---
customers.each do |user|
  checkin_count = user.check_ins.count
  rewards.each do |reward|
    UserReward.find_or_create_by!(user: user, reward: reward) do |ur|
      ur.progress = [checkin_count, reward.required_checkins].min
      ur.redeemed = checkin_count >= reward.required_checkins
    end
  end
end

# --- Chat + Messages (demo conversation) ---
chat = Chat.order(created_at: :desc).find_by(user: demo, studio: studio) ||
       Chat.create!(user: demo, studio: studio, title: "Chat 1")
Message.find_or_create_by!(chat: chat, role: "assistant", content: "Hi! How can I help?")
Message.find_or_create_by!(chat: chat, role: "user", content: "Show me my check-ins")
Message.find_or_create_by!(chat: chat, role: "assistant", content: "You have #{CheckIn.where(user: demo).count} check-ins.")

puts "Seed complete!"
puts "  Admin:  admin@tapin.com / password123"
puts "  Demo:   demo@gmail.com / password123"
puts "  Studio: #{studio.name}"
puts "  Users: #{User.count}, Check-ins: #{CheckIn.count}, Rewards: #{Reward.count}"
