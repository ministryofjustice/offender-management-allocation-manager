class AddParoleRecordsV2 < ActiveRecord::Migration[6.1]
  def change
    create_table :parole_records_v2, id: false do |t|
      t.integer :review_id, primary_key: true
      t.string :nomis_offender_id
      t.date :target_hearing_date
      t.date :custody_report_due
      t.string :review_status
      t.string :hearing_outcome
      t.date :hearing_outcome_received

      t.timestamps
    end
  end
end
