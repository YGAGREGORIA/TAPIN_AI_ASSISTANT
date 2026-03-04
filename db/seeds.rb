puts "Cleaning database..."
UserReward.destroy_all
CheckIn.destroy_all
Course.destroy_all
Deal.destroy_all
Reward.destroy_all
User.destroy_all
Studio.destroy_all

puts "Creating studio..."
studio = Studio.create!(
  name: "Zenith Fitness Studio",
  owner_email: "admin@zenith.com",
  location: "123 Main St, Amsterdam"
)

puts "Creating admin user..."
User.create!(
  email: "admin@zenith.com",
  password: "password",
  first_name: "Studio",
  last_name: "Owner",
  role: "admin",
  studio: studio
)

puts "Creating customers..."
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
  user = User.create!(
    email: data[:email],
    password: "password",
    first_name: data[:first_name],
    last_name: data[:last_name],
    role: "customer",
    studio: studio
  )

  data[:checkins].times do
    CheckIn.create!(
      user: user,
      studio: studio,
      created_at: rand(data[:last_checkin_days_ago]..180).days.ago
    )
  end

  user
end

puts "Creating courses..."
[
  { name: "Yoga Flow",   category: "Mind-Body" },
  { name: "Spin Class",  category: "Cardio" },
  { name: "HIIT",        category: "Cardio" },
  { name: "Pilates",     category: "Mind-Body" },
  { name: "Boxing",      category: "Strength" },
  { name: "Meditation",  category: "Mind-Body" }
].each { |c| Course.create!(studio: studio, **c) }

puts "Creating deals..."
Deal.create!(studio: studio, title: "50% Off First Month", description: "New members get half off their first month", active: true)
Deal.create!(studio: studio, title: "Bring a Friend Week", description: "Bring a friend free all this week", active: true)
Deal.create!(studio: studio, title: "Summer Special", description: "Summer unlimited pass at 30% off", active: false)

puts "Creating rewards..."
bronze     = Reward.create!(studio: studio, name: "Bronze Badge", reward_type: "badge", required_checkins: 10)
silver     = Reward.create!(studio: studio, name: "Silver Badge", reward_type: "badge", required_checkins: 25)
gold       = Reward.create!(studio: studio, name: "Gold Badge",   reward_type: "badge", required_checkins: 50)
free_class = Reward.create!(studio: studio, name: "Free Class",   reward_type: "perk",  required_checkins: 15)

puts "Creating user rewards..."
customers.each do |user|
  checkin_count = user.check_ins.count
  [bronze, silver, gold, free_class].each do |reward|
    progress = [checkin_count, reward.required_checkins].min
    UserReward.create!(
      user: user,
      reward: reward,
      progress: progress,
      redeemed: progress >= reward.required_checkins
    )
  end
end

puts "Seeded: #{Studio.count} studios, #{User.count} users, #{CheckIn.count} check-ins, #{Course.count} courses, #{Deal.count} deals, #{Reward.count} rewards, #{UserReward.count} user_rewards"
