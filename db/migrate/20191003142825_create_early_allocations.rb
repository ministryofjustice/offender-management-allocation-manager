class CreateEarlyAllocations < ActiveRecord::Migration[5.2]
  def change
    create_table :early_allocations do |t|
      t.string :nomis_offender_id, null: false
      t.date :oasys_risk_assessment_date, null: false

      [:convicted_under_terrorisom_act_2000, :high_profile, :serious_crime_prevention_order, :mappa_level_3, :cppc_case].each do |f|
        t.boolean f, null: false
      end

      # nullable booleans are ok here as we will never query on them
      [:high_risk_of_serious_harm, :mappa_level_2, :pathfinder_process, :other_reason, :extremism_separation, :due_for_release_in_less_than_24months].each do |f|
        t.boolean f, null: true
      end

      # These 2 only required for community decision cases
      t.boolean :approved
      t.string :reason

      t.timestamps
    end
  end
end
