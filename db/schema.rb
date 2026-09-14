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

ActiveRecord::Schema[8.1].define(version: 2026_09_14_213929) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "color", default: "#6B7280", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "statements", force: :cascade do |t|
    t.string "bank_name"
    t.datetime "created_at", null: false
    t.datetime "imported_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "source_filename", null: false
    t.string "status", default: "uploaded", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.integer "categorized_by", default: 0, null: false
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.text "description", null: false
    t.text "raw_row"
    t.bigint "statement_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["date"], name: "index_transactions_on_date"
    t.index ["statement_id"], name: "index_transactions_on_statement_id"
  end

  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "statements"
end
