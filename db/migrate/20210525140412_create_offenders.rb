class CreateOffenders < ActiveRecord::Migration[6.0]
  def change
    create_table :offenders, id: false do |t|
      t.string :nomis_offender_id, primary_key: true
      t.timestamps
    end
  end
end
