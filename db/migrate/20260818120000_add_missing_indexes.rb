class AddMissingIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :case_information, :updated_at,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :case_information, :crn,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :allocation_history, :event_trigger,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :responsibilities, :nomis_offender_id,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :early_allocations, :nomis_offender_id,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :parole_reviews, :nomis_offender_id,
              algorithm: :concurrently,
              if_not_exists: true
  end
end
