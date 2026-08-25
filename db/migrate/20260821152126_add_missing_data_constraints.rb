class AddMissingDataConstraints < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    change_column_null :case_information, :nomis_offender_id, false

    change_column_null :allocation_history, :nomis_offender_id, false
    change_column_null :allocation_history, :prison, false
    change_column_null :allocation_history, :event, false
    change_column_null :allocation_history, :event_trigger, false

    change_column_null :early_allocations, :prison, false

    remove_index :responsibilities, :nomis_offender_id,
                 name: :index_responsibilities_on_nomis_offender_id,
                 algorithm: :concurrently

    add_index :responsibilities, :nomis_offender_id,
              unique: true,
              name: :index_responsibilities_on_nomis_offender_id,
              algorithm: :concurrently
  end
end
