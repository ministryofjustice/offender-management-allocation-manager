class CreateEarlyAllocations < ActiveRecord::Migration[5.2]
  def change
    create_table :early_allocations do |t|
      t.string :nomis_offender_id, null: false
      t.date :oasys_risk_assessment_date, null: false

      EarlyAllocation::STAGE1_BOOLEAN_FIELDS.each do |f|
        t.boolean f, null: false
      end

      # nullable booleans are ok here as we will never query on them
      EarlyAllocation::ALL_STAGE2_FIELDS.each do |f|
        t.boolean f, null: true
      end

      # These 2 only required for community decision cases
      t.boolean :approved
      t.string :reason

      t.timestamps
    end
  end
end
