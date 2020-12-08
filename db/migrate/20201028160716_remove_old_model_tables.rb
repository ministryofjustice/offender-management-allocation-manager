class RemoveOldModelTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :delius_data do |t|
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

    drop_table :tier_changes do |t|
      t.string "noms_no"
      t.string "old_tier"
      t.string "new_tier"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "crn"
      t.index ["noms_no"], name: "index_tier_changes_on_noms_no"
    end
  end
end
