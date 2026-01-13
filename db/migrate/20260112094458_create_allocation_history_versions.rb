class CreateAllocationHistoryVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :allocation_history_versions do |t|
      t.string :nomis_offender_id, index: true, null: false
      t.string :prison, index: true, null: false
      t.string :allocated_at_tier
      t.string :override_reasons
      t.string :created_by_name
      t.string :created_by_username
      t.integer :primary_pom_nomis_id, index: true
      t.integer :secondary_pom_nomis_id, index: true
      t.integer :event, index: true, null: false
      t.integer :event_trigger, index: true, null: false
      t.datetime :primary_pom_allocated_at
      t.string :recommended_pom_type

      t.references :allocation_history, foreign_key: { to_table: :allocation_history }, index: true, null: false

      t.datetime :created_at, null: false
      t.datetime :allocation_created_at, null: false
      t.datetime :allocation_updated_at, null: false
    end
  end
end
