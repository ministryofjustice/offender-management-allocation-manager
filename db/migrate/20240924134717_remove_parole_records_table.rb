class RemoveParoleRecordsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :parole_records, id: false do |t|
      t.string :nomis_offender_id, primary_key: true
      t.date :parole_review_date, null: false

      t.timestamps
    end
  end
end
