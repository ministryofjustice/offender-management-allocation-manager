class CreateNewAllocations < ActiveRecord::Migration[6.0]
  def change
    create_table :allocations do |t|
      t.string :nomis_offender_id, null: false
      t.references :pom_detail, null: false, index: true
      t.string :allocation_type, null: false
      t.timestamps

      # Offenders can only have 1 'primary' POM and 1 'coworking' POM
      # Enforce this in the database with a unique composite index
      t.index [:nomis_offender_id, :allocation_type], unique: true
    end
  end
end
