class CreateProbationCaseMerges < ActiveRecord::Migration[8.1]
  def change
    create_table :probation_case_merges do |t|
      t.string :old_crn, null: false
      t.string :new_crn, null: false
      t.boolean :active, null: false, default: true
      t.datetime :superseded_at
      t.timestamps
    end

    add_index :probation_case_merges, :old_crn, unique: true, where: "active = true", name: :idx_probation_case_merges_old_crn_active
    add_index :probation_case_merges, [:new_crn, :active]
  end
end
