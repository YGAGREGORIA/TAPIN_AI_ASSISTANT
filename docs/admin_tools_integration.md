# Admin AI Tools — Integration Guide

## For Navid (Admin Messages Controller)

### How to call a tool

```ruby
result = AdminTools::Registry.call("get_inactive_members", studio: current_user.studio)
# result is a Ruby Hash — call .to_json if needed for the AI response
```

### Available tools

| Tool name | Parameters | Description |
|---|---|---|
| `get_inactive_members` | `days_threshold:` (optional, default 30) | Members with no check-in in N days |
| `analyze_churn_risk` | none | Categorizes all members by risk level |
| `get_member_insights` | `user_id:` (optional) | With user_id: single member detail. Without: members close to rewards |
| `suggest_deal` | none | Generates deal suggestions based on member data |
| `advise_loyalty_program` | none | Retention metrics and improvement recommendations |

### Tool definitions for AI function calling

```ruby
AdminTools::Registry.tool_definitions
# Returns an array of hashes with name, description, parameters
```

### All tools require `studio:` keyword argument

---

## For Iga (Admin Dashboard / Customer Tools)

### User model changes

- `role` column: `"customer"` (default) or `"admin"`
- `studio_id` foreign key (optional)
- Helper methods: `user.admin?`, `user.customer?`
- Associations: `has_many :check_ins`, `has_many :user_rewards`, `has_many :rewards` (through user_rewards)

### Rewards column rename

`rewards.type` was renamed to `rewards.reward_type` (Rails STI conflict). Use `reward.reward_type` everywhere.

### Tier logic

Used in customer dashboard — extract if needed:

- 0–9 check-ins → Member
- 10–24 → Bronze
- 25–49 → Silver
- 50+ → Gold

---

## Seed Data

Run `rails db:seed` to populate test data.

**Login credentials:**
- Admin: `admin@zenith.com` / `password`
- Customers: `alice@example.com`, `bob@example.com`, etc. / `password`

**Data includes:**
- 1 studio, 1 admin, 8 customers
- Varied check-in patterns (active, inactive 45+ days, churn risk 60+ days, close to reward)
- 6 courses, 3 deals, 4 rewards with user progress
