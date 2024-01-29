class CreateParoleReviewImports < ActiveRecord::Migration[6.1]
  def change
    create_table :parole_review_imports do |t|
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

      # Meta data
      t.date :snapshot_date
      t.integer :row_number
      t.string :import_id
      t.boolean :single_day_snapshot
      t.date :processed_on

      t.timestamps

      t.index [:snapshot_date, :row_number], unique: true, name: :index_parole_review_imports_on_snapshot_date_row_number
      t.index :processed_on, name: :index_parole_review_imports_on_processed_on
    end
  end
end
