class AddOverridesTable < ActiveRecord::Migration[5.2]
  create_table "overrides", force: :cascade do |t|
    t.integer "nomis_staff_id"
    t.string "nomis_offender_id"
    t.string "override_reason"
    t.string "more_detail"
  end
end
