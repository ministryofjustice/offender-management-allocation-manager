class CreateHandoverProgressChecklists < ActiveRecord::Migration[6.1]
  def change
    create_table :handover_progress_checklists do |t|
      t.references :nomis_offender,
                   type: :string, null: false,
                   index: { unique: true },
                   foreign_key: { to_table: :offenders, primary_key: :nomis_offender_id }
      t.boolean :reviewed_oasys, null: false, default: false
      t.boolean :contacted_com, null: false, default: false
      t.boolean :sent_handover_report, null: false, default: false
      t.timestamps null: true
    end
  end
end
