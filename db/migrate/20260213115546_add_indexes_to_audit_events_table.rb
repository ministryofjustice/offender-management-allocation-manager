class AddIndexesToAuditEventsTable < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :audit_events, :nomis_offender_id, algorithm: :concurrently
    add_index :audit_events, :tags, using: :gin, algorithm: :concurrently
    add_index :audit_events, :created_at, algorithm: :concurrently
    add_index :audit_events, [:nomis_offender_id, :created_at], order: { created_at: :desc }, algorithm: :concurrently

    remove_column :audit_events, :published_at, :datetime, precision: 6
    remove_column :audit_events, :updated_at, :datetime, precision: 6
  end
end
