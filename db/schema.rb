# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_02_21_082427) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "allocations", force: :cascade do |t|
    t.string "nomis_offender_id"
    t.string "prison"
    t.string "allocated_at_tier"
    t.string "override_reasons"
    t.string "override_detail"
    t.string "created_by"
    t.boolean "active"
    t.bigint "pom_detail_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "nomis_staff_id"
    t.integer "nomis_booking_id"
    t.text "message"
    t.index ["nomis_offender_id"], name: "index_allocations_on_nomis_offender_id"
    t.index ["nomis_staff_id"], name: "index_allocations_on_nomis_staff_id"
  end

  create_table "case_information", force: :cascade do |t|
    t.string "tier"
    t.string "case_allocation"
    t.string "nomis_offender_id"
    t.index ["nomis_offender_id"], name: "index_case_information_on_nomis_offender_id"
  end

  create_table "overrides", force: :cascade do |t|
    t.integer "nomis_staff_id"
    t.string "nomis_offender_id"
    t.string "override_reasons"
    t.string "more_detail"
  end

  create_table "pom_details", force: :cascade do |t|
    t.integer "nomis_staff_id"
    t.float "working_pattern"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nomis_staff_id"], name: "index_pom_details_on_nomis_staff_id"
  end

  add_foreign_key "allocations", "pom_details"
end
