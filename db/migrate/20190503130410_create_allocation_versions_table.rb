# frozen_string_literal: true

class CreateAllocationVersionsTable < ActiveRecord::Migration[5.2]
  def up
    create_table :allocation_versions do |t|
      t.string :nomis_offender_id
      t.string :prison
      t.string :allocated_at_tier
      t.string :override_reasons
      t.string :override_detail
      t.string :message
      t.string :suitability_detail
      t.string :primary_pom_name
      t.string :secondary_pom_name
      t.string :created_by_name
      t.integer :primary_pom_nomis_id
      t.integer :secondary_pom_nomis_id
      t.integer :nomis_booking_id
      t.integer :event
      t.integer :event_trigger
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.timestamps
      t.index [:nomis_offender_id], name: :index_allocation_versions_on_nomis_offender_id
      t.index [:primary_pom_nomis_id], name: :index_allocation_versions_on_primary_pom_nomis_id
      t.index [:secondary_pom_nomis_id], name: :index_allocation_versions_secondary_pom_nomis_id
    end

    def down
      drop_table :allocation_versions
    end
  end
end
