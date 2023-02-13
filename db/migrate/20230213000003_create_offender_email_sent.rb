class CreateOffenderEmailSent < ActiveRecord::Migration[6.1]
  def change
    create_table :offender_email_sent do |t|
      t.references :nomis_offender, type: :string, null: false,
                   index: { unique: true },
                   foreign_key: { to_table: :offenders, primary_key: :nomis_offender_id }
      t.column :offender_email_type, :offender_email_type, null: false

      t.timestamps null: false
    end
  end
end
