class AddIndexesToAuditEventsTable < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :audit_events, :nomis_offender_id, algorithm: :concurrently
    add_index :audit_events, :tags, using: :gin, algorithm: :concurrently
    add_index :audit_events, :published_at, algorithm: :concurrently
    add_index :audit_events, [:nomis_offender_id, :published_at], order: { published_at: :desc }, algorithm: :concurrently
  end
end
