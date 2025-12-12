class CreateOmicEligibilities < ActiveRecord::Migration[8.0]
  def change
    create_table :omic_eligibilities, id: false, primary_key: :nomis_offender_id do |t|
      t.string :nomis_offender_id
      t.boolean :eligible, default: false

      t.timestamps
      t.index :nomis_offender_id, unique: true
      t.index :eligible
    end
  end
end
