class CreateResponsibilities < ActiveRecord::Migration[5.2]
  def change
    create_table :responsibilities do |t|
      t.string :nomis_offender_id, null: false
      t.integer :reason, null: false
      t.string :reason_text
      t.string :value, null: false

      t.timestamps
    end
  end
end
