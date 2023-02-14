class CreateOffenderEmailOptOuts < ActiveRecord::Migration[6.1]
  def change
    create_table :offender_email_opt_outs do |t|
      t.string :staff_member_id, null: false
      t.column :offender_email_type, :offender_email_type, null: false

      t.timestamps null: false

      t.index [:staff_member_id, :offender_email_type], unique: true,
              name: :index_offender_email_opt_out_unique_composite_key
    end
  end
end
