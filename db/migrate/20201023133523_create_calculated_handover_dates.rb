class CreateCalculatedHandoverDates < ActiveRecord::Migration[6.0]
  def change
    create_table :calculated_handover_dates do |t|
      t.date :start_date
      t.date :handover_date
      t.string :reason, null: false

      t.timestamps

      t.references :nomis_offender,
                   type: :string, null: false,
                   index: { unique: true },
                   foreign_key: {
                     to_table: :case_information,
                     primary_key: :nomis_offender_id,
                     on_delete: :cascade,
                     on_update: :cascade
                   }
    end
  end
end
