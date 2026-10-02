class AddHistoryLookupIndexesToVersions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :versions, [:nomis_offender_id, :created_at],
              where: "event = 'update' AND item_type IN ('CaseInformation', 'CalculatedHandoverDate')",
              name: 'index_versions_on_significant_change_history',
              algorithm: :concurrently
  end
end
