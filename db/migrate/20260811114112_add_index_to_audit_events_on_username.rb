class AddIndexToAuditEventsOnUsername < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :audit_events, :username, algorithm: :concurrently
  end
end
