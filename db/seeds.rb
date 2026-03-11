puts "Seeding..."

# --- Studio ---
studio = Studio.find_or_create_by!(name: "TAPIN Studio") do |s|
  s.location = "Hamburg"
  s.owner_email = "admin@tapin.com"
end
studio.update!(
  address: "Schulterblatt 58, 20357 Hamburg (Schanzenviertel)",
  phone: "+49 40 555 0123",
  email: "hello@tapin-studio.de",
  opening_hours: "Mon-Fri 6:00-22:00, Sat 8:00-20:00, Sun 9:00-18:00",
  facilities: "Changing rooms with showers and lockers (bring your own lock or rent for 1 EUR). Juice bar with smoothies, protein shakes, and snacks. Free WiFi. Towel rental: 2 EUR. Parking: street parking available, nearest garage at Schanzenhoefe (3 min walk). Public transport: U3 Feldstrasse (5 min walk) or Bus 15 Schulterblatt (1 min walk).",
  pricing: "Drop-in: 15 EUR per class. Starter (10 classes/month): 99 EUR/month. Unlimited: 139 EUR/month. Annual Unlimited: 119 EUR/month (billed yearly). Student discount: 20% off any plan with valid student ID."
)

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
courses_data = [
  {
    name: "HIIT Express", category: "fitness",
    schedule: "Mon/Wed/Fri 7:00, 12:15, 18:30", duration: 30, difficulty: "Intermediate-Advanced",
    description: "High-intensity interval training with bodyweight and light equipment. Short bursts of all-out effort followed by brief rest. Burns calories fast.",
    benefits: "Cardiovascular fitness, fat burning, metabolic boost, time-efficient",
    what_to_bring: "Water bottle, towel, athletic shoes with good grip",
    what_to_wear: "Breathable moisture-wicking clothes, supportive sports bra",
    recovery_tips: "Expect muscle soreness 24-48h after. Stretch hamstrings, quads, and shoulders. Hydrate well. Rest at least 1 day between sessions.",
    best_for: "People short on time who want maximum results. Not recommended for complete beginners."
  },
  {
    name: "Yoga Flow", category: "mind-body",
    schedule: "Mon/Wed/Fri 8:30, Tue/Thu 17:30, Sat 10:00, Sun 11:00", duration: 60, difficulty: "All levels",
    description: "Vinyasa-style yoga linking breath to movement. Flowing sequences build strength, flexibility, and calm. Each class ends with a 5-min savasana.",
    benefits: "Flexibility, stress relief, core strength, balance, better sleep, injury prevention",
    what_to_bring: "Yoga mat (studio mats available for free), water bottle, optional towel",
    what_to_wear: "Comfortable stretchy clothes. Barefoot — no shoes needed.",
    recovery_tips: "Mild soreness in hips and shoulders is normal for beginners. Gentle stretching on rest days helps. Stay hydrated.",
    best_for: "Everyone. Great first class for beginners. Also excellent active recovery for athletes."
  },
  {
    name: "Boxing Basics", category: "combat",
    schedule: "Tue/Thu 7:00, 18:00, Sat 12:00", duration: 45, difficulty: "Beginner-Intermediate",
    description: "Learn fundamental boxing techniques — jab, cross, hook, uppercut — on heavy bags and pads. Includes footwork drills and a cardio finisher.",
    benefits: "Full-body workout, stress relief, coordination, upper body strength, confidence",
    what_to_bring: "Water bottle, towel. Hand wraps provided free on first visit (then bring your own or buy at reception for 8 EUR). Boxing gloves available to borrow.",
    what_to_wear: "Athletic clothes, flat-soled shoes or boxing shoes. Avoid loose jewelry.",
    recovery_tips: "Expect sore shoulders, forearms, and core. Ice any tender knuckles. Stretch wrists and shoulders after class. 1-2 rest days between sessions.",
    best_for: "Anyone wanting a fun, empowering workout. Great stress reliever. No prior experience needed."
  },
  {
    name: "Pilates", category: "mind-body",
    schedule: "Mon/Wed 9:30, Tue/Thu 12:00, Fri 16:00", duration: 50, difficulty: "All levels",
    description: "Mat-based Pilates focusing on core strength, posture, and controlled movement. Uses resistance bands and small balls for added challenge.",
    benefits: "Core strength, posture improvement, back pain relief, flexibility, body awareness",
    what_to_bring: "Yoga/Pilates mat (studio mats available), water bottle, grip socks recommended",
    what_to_wear: "Form-fitting clothes so the instructor can check your alignment. Barefoot or grip socks.",
    recovery_tips: "Mild core soreness is normal. Light walking and gentle stretches help. You can do Pilates on consecutive days as it's low-impact.",
    best_for: "Beginners, desk workers with back pain, anyone rehabbing from injury, pregnant members (let instructor know)."
  },
  {
    name: "Spin Class", category: "cardio",
    schedule: "Mon/Wed/Fri 6:30, Tue/Thu 18:30, Sat 9:00", duration: 45, difficulty: "All levels",
    description: "Indoor cycling to energizing music. Intervals of sprints, climbs, and recovery. Instructor-led with motivating coaching. Dark room with disco lights.",
    benefits: "Massive calorie burn, leg strength, cardiovascular endurance, low joint impact, mood boost",
    what_to_bring: "Water bottle (you'll need it), towel, cycling shoes optional (SPD-compatible pedals, regular athletic shoes also work with toe cages)",
    what_to_wear: "Padded cycling shorts recommended for comfort (not required), moisture-wicking top",
    recovery_tips: "Legs may feel heavy after. Stretch quads, calves, and hip flexors. Foam rolling helps. Hydrate and eat within 30 min after class.",
    best_for: "Anyone who loves music-driven workouts. Easy to scale — beginners just lower resistance."
  },
  {
    name: "Meditation & Breathwork", category: "mind-body",
    schedule: "Tue/Thu 8:00, Sun 10:00", duration: 30, difficulty: "All levels",
    description: "Guided meditation and breathing exercises. Techniques include box breathing, body scan, and visualization. A calm start or end to your day.",
    benefits: "Stress reduction, mental clarity, better sleep, anxiety management, focus",
    what_to_bring: "Nothing required. Optional: your own cushion or blanket. Mats and bolsters provided.",
    what_to_wear: "Anything comfortable and warm. You'll be still, so layers help.",
    recovery_tips: "No physical recovery needed. Try to maintain 5 min of daily practice at home for best results.",
    best_for: "Everyone, especially those dealing with stress, anxiety, or sleep issues. Pairs well with any physical class."
  },
  {
    name: "Strength & Conditioning", category: "fitness",
    schedule: "Mon/Wed/Fri 17:00, Sat 11:00", duration: 50, difficulty: "Intermediate",
    description: "Barbell and dumbbell training focused on compound lifts — squats, deadlifts, presses, rows. Structured programming that builds real strength over weeks.",
    benefits: "Muscle building, bone density, metabolism boost, functional strength, posture",
    what_to_bring: "Water bottle, towel, flat-soled shoes or lifting shoes. Lifting gloves optional.",
    what_to_wear: "Fitted athletic wear (avoid baggy clothes near barbells). Flat shoes preferred.",
    recovery_tips: "Expect DOMS (delayed onset muscle soreness) 24-72h after. Protein within 30 min post-workout helps recovery. Sleep 7-9h. Rest 48h before working same muscle group.",
    best_for: "Anyone wanting to get stronger. Some gym experience helpful but not required — instructor teaches proper form."
  },
  {
    name: "Dance Cardio", category: "cardio",
    schedule: "Tue 19:00, Sat 14:00", duration: 45, difficulty: "Beginner",
    description: "Fun, high-energy dance routines set to pop, Latin, and hip-hop music. No choreography experience needed — just follow along and have fun.",
    benefits: "Cardio fitness, coordination, mood boost, calorie burn, social connection",
    what_to_bring: "Water bottle, towel",
    what_to_wear: "Comfortable clothes you can move freely in, supportive athletic shoes",
    recovery_tips: "Light soreness in legs and core. Stretch calves and hips after. Stay hydrated.",
    best_for: "Anyone who finds traditional cardio boring. Great social class — come with friends!"
  }
]

courses_data.each do |data|
  course = Course.find_or_create_by!(studio: studio, name: data[:name]) do |c|
    c.category = data[:category]
  end
  course.update!(data.except(:name))
end

# --- Deals ---
[
  ["2-for-1 Trial Week", "Bring a friend and both train free for a week. Available for all membership types.", true],
  ["10% off Monthly", "Save 10% on your first month of any membership plan. Use code WELCOME10 at signup.", true],
  ["Summer Body Challenge", "8-week program: nutrition guide + 3 classes/week for 199 EUR. Starts every month.", true],
  ["Free Protein Shake", "Get one free shake at the juice bar after your next class. Show your check-in.", false],
  ["Student Discount", "20% off any membership plan with valid student ID. Show at reception.", true]
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
