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

ActiveRecord::Schema[8.1].define(version: 2026_05_10_235634) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", id: { type: :string, limit: 25 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "borrowers", id: { type: :string, limit: 25 }, force: :cascade do |t|
    t.string "account_id", limit: 25, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_borrowers_on_account_id"
  end

  create_table "loans", id: { type: :string, limit: 25 }, force: :cascade do |t|
    t.string "account_id", limit: 25, null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.decimal "annual_interest_rate", precision: 5, scale: 2, null: false
    t.string "borrower_id", limit: 25, null: false
    t.datetime "created_at", null: false
    t.date "start_date", null: false
    t.integer "term_months", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_loans_on_account_id"
    t.index ["borrower_id"], name: "index_loans_on_borrower_id"
  end

  create_table "payments", id: { type: :string, limit: 25 }, force: :cascade do |t|
    t.string "account_id", limit: 25, null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.decimal "interest_applied", precision: 12, scale: 2, null: false
    t.string "loan_id", limit: 25, null: false
    t.decimal "principal_applied", precision: 12, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_payments_on_account_id"
    t.index ["loan_id"], name: "index_payments_on_loan_id"
  end

  create_table "sessions", id: { type: :string, limit: 25 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.string "user_id", limit: 25, null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", id: { type: :string, limit: 25 }, force: :cascade do |t|
    t.string "account_id", limit: 25, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end
end
