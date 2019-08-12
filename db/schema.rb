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

ActiveRecord::Schema.define(version: 2019_08_12_124731) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "allocation_versions", force: :cascade do |t|
    t.string "nomis_offender_id"
    t.string "prison"
    t.string "allocated_at_tier"
    t.string "override_reasons"
    t.string "override_detail"
    t.string "message"
    t.string "suitability_detail"
    t.string "primary_pom_name"
    t.string "secondary_pom_name"
    t.string "created_by_name"
    t.integer "primary_pom_nomis_id"
    t.integer "secondary_pom_nomis_id"
    t.integer "nomis_booking_id"
    t.integer "event"
    t.integer "event_trigger"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_username"
    t.datetime "primary_pom_allocated_at"
    t.string "recommended_pom_type"
    t.index ["nomis_offender_id"], name: "index_allocation_versions_on_nomis_offender_id"
    t.index ["primary_pom_nomis_id"], name: "index_allocation_versions_on_primary_pom_nomis_id"
    t.index ["secondary_pom_nomis_id"], name: "index_allocation_versions_secondary_pom_nomis_id"
  end

  create_table "case_information", force: :cascade do |t|
    t.string "tier"
    t.string "case_allocation"
    t.string "nomis_offender_id"
    t.text "omicable"
    t.string "crn"
    t.integer "mappa_level"
    t.boolean "manual_entry", null: false
    t.bigint "local_divisional_unit_id"
    t.bigint "team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["local_divisional_unit_id"], name: "index_case_information_on_local_divisional_unit_id"
    t.index ["nomis_offender_id"], name: "index_case_information_on_nomis_offender_id", unique: true
    t.index ["team_id"], name: "index_case_information_on_team_id"
  end

  create_table "delius_data", force: :cascade do |t|
    t.string "crn"
    t.string "pnc_no"
    t.string "noms_no"
    t.string "fullname"
    t.string "tier"
    t.string "roh_cds"
    t.string "offender_manager"
    t.string "org_private_ind"
    t.string "org"
    t.string "provider"
    t.string "provider_code"
    t.string "ldu"
    t.string "ldu_code"
    t.string "team"
    t.string "team_code"
    t.string "mappa"
    t.string "mappa_levels"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "date_of_birth"
    t.index ["crn"], name: "index_delius_data_on_crn", unique: true
  end

  create_table "delius_import_errors", force: :cascade do |t|
    t.string "nomis_offender_id"
    t.integer "error_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "flipflop_features", force: :cascade do |t|
    t.string "key", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "local_divisional_units", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_local_divisional_units_on_code"
  end

  create_table "overrides", force: :cascade do |t|
    t.integer "nomis_staff_id"
    t.string "nomis_offender_id"
    t.string "override_reasons"
    t.string "more_detail"
    t.string "suitability_detail"
  end

  create_table "pom_details", force: :cascade do |t|
    t.integer "nomis_staff_id"
    t.float "working_pattern"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nomis_staff_id"], name: "index_pom_details_on_nomis_staff_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_teams_on_code"
  end

  create_table "tier_changes", force: :cascade do |t|
    t.string "noms_no"
    t.string "old_tier"
    t.string "new_tier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "crn"
    t.index ["noms_no"], name: "index_tier_changes_on_noms_no"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

end
