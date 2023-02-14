class CreateOffenderEmailSent < ActiveRecord::Migration[6.1]
  def change
    create_table :offender_email_sent do |t|
      t.references :nomis_offender, type: :string, null: false,
                   foreign_key: { to_table: :offenders, primary_key: :nomis_offender_id }
      t.string :staff_member_id, null: false
      t.column :offender_email_type, :offender_email_type, null: false

      t.timestamps null: false

      t.index [:nomis_offender_id, :staff_member_id, :offender_email_type], unique: true,
              name: :index_offender_email_sent_unique_composite_key
    end
  end
end
