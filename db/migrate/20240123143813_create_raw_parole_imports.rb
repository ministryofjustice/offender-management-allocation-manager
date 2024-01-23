class CreateRawParoleImports < ActiveRecord::Migration[6.1]
  def change
    create_table :raw_parole_imports do |t|
      t.string :title
      t.string :nomis_id
      t.string :prison_no
      t.string :sentence_type
      t.string :sentence_date
      t.string :tariff_exp
      t.string :review_date
      t.string :review_id
      t.string :review_milestone_date_id
      t.string :review_type
      t.string :review_status
      t.string :curr_target_date
      t.string :ms13_target_date
      t.string :ms13_completion_date
      t.string :final_result
      t.date :for_date
      t.string :import_id

      t.timestamps
    end
  end
end
