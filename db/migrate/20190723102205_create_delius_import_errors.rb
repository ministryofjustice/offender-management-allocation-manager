class CreateDeliusImportErrors < ActiveRecord::Migration[5.2]
  def change
    create_table :delius_import_errors do |t|
      t.string :nomis_offender_id
      t.integer :error_type

      t.timestamps
    end
  end
end
