# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_04_123109) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "status"
    t.bigint "studio_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["studio_id"], name: "index_chats_on_studio_id"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "check_ins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "studio_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["studio_id"], name: "index_check_ins_on_studio_id"
    t.index ["user_id"], name: "index_check_ins_on_user_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "studio_id", null: false
    t.datetime "updated_at", null: false
    t.index ["studio_id"], name: "index_courses_on_studio_id"
  end

  create_table "deals", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "studio_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["studio_id"], name: "index_deals_on_studio_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.string "role"
    t.string "sentiment"
    t.text "summary"
    t.string "tag"
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
  end

  create_table "rewards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "required_checkins"
    t.string "reward_type"
    t.bigint "studio_id", null: false
    t.datetime "updated_at", null: false
    t.index ["studio_id"], name: "index_rewards_on_studio_id"
  end

  create_table "studios", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "location"
    t.string "name"
    t.string "owner_email"
    t.datetime "updated_at", null: false
  end

  create_table "user_rewards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "progress"
    t.boolean "redeemed"
    t.bigint "reward_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["reward_id"], name: "index_user_rewards_on_reward_id"
    t.index ["user_id"], name: "index_user_rewards_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "phone_number"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "customer", null: false
    t.bigint "studio_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["studio_id"], name: "index_users_on_studio_id"
  end

  add_foreign_key "chats", "studios"
  add_foreign_key "chats", "users"
  add_foreign_key "check_ins", "studios"
  add_foreign_key "check_ins", "users"
  add_foreign_key "courses", "studios"
  add_foreign_key "deals", "studios"
  add_foreign_key "messages", "chats"
  add_foreign_key "rewards", "studios"
  add_foreign_key "user_rewards", "rewards"
  add_foreign_key "user_rewards", "users"
  add_foreign_key "users", "studios"
end
